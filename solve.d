import std.stdio: writeln, File;
import std.container.array: Array;
import std.math: sqrt, abs, pow;
import std.container.binaryheap: BinaryHeap;
import std.format: format;
import std.datetime.stopwatch: StopWatch;
import std.conv: to, ConvException;
import std.file: exists;
import std.parallelism: parallel;

bool showClosed = false, showOpen = false;
uint uh = 0;

enum SolveFlags
{
    NONE = 0,
    HORIZONTAL = (1 << 0),
    DIAGONAL = (1 << 1),
    TIE_BREAKER = (1 << 2),
}

double heuristic(Node current, Node start, Node end, bool breakTies)
{
    //we'll just use euclidean
    
    //double result = abs(sqrt(cast(float)pow(current.x - end.x, 2) + cast(float)pow(current.y - end.y, 2)));
    //double result = abs(cast(float)(current.x - end.x)) + abs(cast(float)(current.y - end.y));
    double result;
    switch (uh)
    {
        default:
        //dijkstra
            result = 1;
        break;
        case 1:
            result = abs(cast(float)(current.x - end.x)) + abs(cast(float)(current.y - end.y));
        break;
        case 2:
            result = abs(sqrt(cast(float)pow(current.x - end.x, 2) + cast(float)pow(current.y - end.y, 2)));
        break;
    }
    if (breakTies == true)
    {
        //tie-breaker
        /*http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html#breaking-ties*/
        int dx1 = current.x - end.x;
        int dy1 = current.y - end.y;
        int dx2 = start.x - end.x;
        int dy2 = start.y - end.y;
        double cross = abs(dx1*dy2 - dx2*dy1);
        return result + (cross*0.01);
    }
    else return result;
}

class Node
{
public:
    this(int x, int y, double g, double h, double f, Node parent = null)
    {
        this._x = x;
        this._y = y;
        this._g = g;
        this._h = h;
        this._f = f;
        this._parent = parent;
    }
    this(int x, int y, Node parent, Node end, Node start, bool breakTies)
    {
        this._x = x;
        this._y = y;
        this._parent = parent;
        /*DDDDDDDDDDDD is sooooooooo goooood. passing "this" as a parameter.....
            uggggggggggggggggghhhhhhhhhhhhhhh why can't c++ be like D*/
        this._g = parent.g + 1;
        this._h = heuristic(this, end, start, breakTies);
        this._f = this._g + this._h;
    }
    double g() { return this._g; }
    double h() { return this._h; }
    double f() { return this._f; }
    int x() { return this._x; }
    int y() { return this._y; }
    Node parent() { return this._parent; }
    double[] opIndex()
    {
        return [cast(double)_x, cast(double)_y, _g, _h, _f];
    }
    override int opCmp(Object other)
    {
        if (other is null || this is null)
            return 0;
        if (_f == (cast(Node)other).f)
            return 0;
        return _f < (cast(Node)other).f ? 1 : -1;//cast(int)(cast(Node)other).f - cast(int)_f;
    }
    override string toString()
    {
        return format("[%d, %d, %f, %f, %f]", _x, _y, _g, _h, _f);
    }
    override bool opEquals(Object other)
    {
        if (this is null || other is null)
            return false;
        if (this is other)
            return true;
        return _f == (cast(Node)other).f;
    }
private:
    int _x, _y;
    double _g, _h, _f;
    Node _parent;
}

bool nodeExists(Array!Node nodes, Node n)
{
    foreach (tmp; nodes)
        if (n.x == tmp.x && n.y == tmp.y)
            return true;
    return false;
}

Node getBestNode(ref NodeStack stack, ref NodeSet closed)
{
    bool valid = false;
    Node bestNode;
    do
    {
        bestNode = stack.pop();
        if (closed.nodeExists(bestNode) == false)
            valid = true;
    } while (valid == false);
    return bestNode;
}

Node getBestNode(ref BinaryHeap!(Node[]) heap, ref NodeSet closed)
{
    bool valid = false;
    Node bestNode;
    do
    {
        bestNode = heap.front();
        if (closed.nodeExists(bestNode) == false)
            valid = true;
        else
            heap.popFront();
    } while (valid == false);
    heap.popFront();
    return bestNode;
}

class Field
{
public:
    this(int width, int height, char whitespace, char movable)
    {
        this.width = width;
        this.height = height;
        foreach (i; 0..height)
        {
            char[] push;
            foreach (x; 0..width)
            {
                push ~= whitespace;
            }
            this.field ~= push;
        }
        this.mov = movable;
    }
    override string toString()
    {
        string ret;
        foreach (s; this.field)
        {
            foreach (c; s)
                ret ~= c;
            ret ~= '\n';
        }
        return ret;
    }
    void replace(Node n, char x)
    {
        this.field[n.y][n.x] = x;
    }
    void pushln(string ln)
    {
        char[] build;
        foreach (c; ln)
            build ~= c;
        this.field ~= build;
    }
    void reset()
    {
        this.field = [][];
    }
    bool movable(Node n)
    {
        if (n.x >= 0 && n.x < this.field[0].length && n.y >= 0 && n.y < this.field.length)
            return this.field[n.y][n.x] == mov;
        return false;
    }
private:
    int width, height;
    char mov;
    char[][] field;
}

Array!Node getSuccessors(Node current, Node start, Node end, uint flags)
{
    Array!Node successors;
    static auto push = function(ref Array!Node a, Node n) => a.insertBack(n);
    bool breakTies = !(flags & SolveFlags.TIE_BREAKER) == 0;
    if (flags & SolveFlags.HORIZONTAL)
    {
        push(successors, new Node(current.x + 1, current.y, current, end, start, breakTies));
        push(successors, new Node(current.x - 1, current.y, current, end, start, breakTies));
        push(successors, new Node(current.x, current.y + 1, current, end, start, breakTies));
        push(successors, new Node(current.x, current.y - 1, current, end, start, breakTies));
    }

    if (flags & SolveFlags.DIAGONAL)
    {
        push(successors, new Node(current.x + 1, current.y + 1, current, end, start, breakTies));
        push(successors, new Node(current.x - 1, current.y - 1, current, end, start, breakTies));
        push(successors, new Node(current.x - 1, current.y + 1, current, end, start, breakTies));
        push(successors, new Node(current.x + 1, current.y - 1, current, end, start, breakTies));
    }
    return successors;
}

Array!Node Astar(Node start, Node end, int width, int height, ref Field field, uint expected,
                 uint flags = SolveFlags.HORIZONTAL | SolveFlags.DIAGONAL | SolveFlags.TIE_BREAKER)
{
    //BinaryHeap!(Node[]) open = BinaryHeap!(Node[])([]);
    NodeStack open = new NodeStack();
    NodeSet closed = new NodeSet();
    open.insert(start);
    while (open.length != 0)
    {
        Node q = getBestNode(open, closed);
        //get potential nodes
        Array!Node successors = getSuccessors(q, end, start, flags);
        foreach(n; successors)
        {
            if (n.x == end.x && n.y == end.y)
            {
                Array!Node path;
                Node tmp = n;
                path.insertBack(tmp);
                do
                {
                    tmp = tmp.parent;
                    path.insertBack(tmp);
                } while (tmp.parent !is null);
                if (showClosed == true)
                    foreach (z; closed.parallel)
                        field.replace(z, 'o');
                if (showOpen == true)
                    foreach(z; open.parallel)
                        field.replace(z, 'x');
                writeln("closed length: ", closed.length);
                writeln("insert count: ", closed.insertCount);
                writeln("failed insert count: ", closed.errorCount);
                writeln("open length: ", open.length);
                writeln("explored vs nodes ratio: ", cast(double)closed.length / cast(double)expected);
                writeln("solution length: ", path.length);
                return path;
            }
            else if (n.x >= 0 && n.x <= width && n.y >= 0 && n.y <= height
                     //&& closed.nodeExists(n) == false //using this adds ~18% more time
                     && field.movable(n) == true)
            {
                //TODO: store modification. Replace nodes with same x & y values but lower f values
                //if (closed.exists(n) == false)
                open.insert(n);
            }
        }
        closed.insert(q);
        if (closed.length == expected)
        {
            //return an empty array if we cannot find a path
            return Array!Node();
        }
    }
    return Array!Node();
}

//NodeStack is a stack implementation allowing for quick retrieval of Nodes, with the only cost associtated being insertion
//this doesn't seem to reduce solve time a lot :(
class NodeStack
{
public:
    this()
    {
        
    }
    /*
        the downside of this stack method is there is a O(length) worst case complexity for insertion...ouch
        but there is a really quick time to get the front node
    */
    void insert(Node n)
    {
        if (this.stack.length == 0)
            this.stack ~= n;
        else
        {
            uint index = 0;
            Node lookup = this.stack[index];
            while (n < lookup)
            {
                index++;
                if (index == this.stack.length)
                    break;
                lookup = this.stack[index];
            }
            if (index == this.stack.length)
                this.stack ~= n;
            else
                this.stack = this.stack[0..index] ~ n ~ this.stack[index..$];
        }
    }
    void insert(Node[] inserts)
    {
        foreach (n; inserts)
            this.insert(n);
    }
    Node pop(uint index)
    {
        Node ret = this.stack[index];
        this.stack = this.stack[0..index] ~ this.stack[index + 1..$];
        return ret;
    }
    Node pop()
    {
        return this.pop(0);
    }
    Node[] take(uint num, uint index)
    {
        Node[] ret;
        foreach(n; this.stack[index..index + num])
            ret ~= n;
        return ret;
    }
    ulong length()
    {
        return this.stack.length;
    }
    override string toString()
    {
        string ret;
        foreach (n; this.stack)
            ret ~= n.toString ~ '\n';
        return ret;
    }

        /*
        empty (first iteration only)
        front
        <body>
        popFront
        empty
    */
    @property bool empty()
    {
        if (this.frontCheck == false)
        {
            this.index = 0;
            this.hasNode = false;
        }
        if (this.hasNode == true)
            return false;
        this.n = this.stack[this.index++];
        if (this.index == this.length)
        {
            this.index = 0;
            return true;
        }
        this.hasNode = true;
        return false;
    }
    @property Node front()
    {
        this.frontCheck = false;
        return n;
    }
    void popFront()
    {
        this.frontCheck = true;
        this.hasNode = false;
    }

private:
    Node[] stack;

    Node n;
    uint index;
    bool hasNode, frontCheck;
}

//if i'm bored in the future, I will update this to use trees as the underlying structure
//but for now i'm not motivated enough to figure out how to make a multidimensional tree structure
//when i can barely make a tree by myself
class NodeSet
{
public:
    this()
    {
        //blah blah blah
        this.cnt = 0;
        this.errcnt = 0;
    }
    //returns true if a new node was inserted or replaced another node
    //returns false if a node already exists and the inserting node's f-value is greater than or equal
    //to the node already in the list
    bool insert(Node n)
    {
        if (this.set.length == 0)
        {
            //this node and no parent
            this.set ~= n;
        this.cnt++;
            return true;
        }
        foreach (c; this.set)
        {
            if (n.x == c.x && n.y == c.y && n.f < c.f)
            {
                c = n;
            this.cnt++;
                return true;
            }
            else if (n.x == c.x && n.y == c.y)
            {
                this.errcnt++;
                return false;
            }
        }
        this.cnt++;
        this.set ~= n;
        return true;
    }
    ulong length()
    {
        return this.set.length;
    }
    bool nodeExists(Node n)
    {
        foreach (c; this.set)
            if (n.x == c.x && n.y == c.y)
                return true;
        return false;
    }
    uint insertCount()
    {
        return this.cnt;
    }
    uint errorCount()
    {
        return this.errcnt;
    }
    /*
        empty (first iteration only)
        front
        <body>
        popFront
        empty
    */
    @property bool empty()
    {
        if (this.frontCheck == false)
        {
            this.index = 0;
            this.hasNode = false;
        }
        if (this.hasNode == true)
            return false;
        this.n = this.set[this.index++];
        if (this.index == this.length)
        {
            this.index = 0;
            return true;
        }
        this.hasNode = true;
        return false;
    }
    @property Node front()
    {
        this.frontCheck = false;
        return n;
    }
    void popFront()
    {
        this.frontCheck = true;
        this.hasNode = false;
    }
private:
    uint cnt;
    uint errcnt;

    Node n;
    uint index;
    bool hasNode, frontCheck;

    Node[] set;
}

int main(string[] args)
{
    if (args.length <= 1)
    {
        writeln("[error] no parameters provided");
        return 1;
    }
    uint uflag = 0;
    uint mode = -1;
    int SIZE;
    string file;
    for (uint i = 1; i < args.length; i++)
    {
        switch (args[i])
        {
            default:
                writeln("[error] \'", args[i], "\' unrecognized");
                return 1;
            break;
            case "--help":
                writeln("commands: ");
                writeln("\t--help: list of commands");
                writeln("\t--diagonal: move diagonally");
                writeln("\t--horizontal: move up, down, left, and right");
                writeln("\t--break-ties: use a tie-breaker");
                writeln("\t--size <n>: create a maze of n width and n height and solve it");
                writeln("\t--file <f>: read maze from file and solve it. Whitespace must be used in the paths, and start must be marked by @ character, and end marked by X character");
                writeln("\t--show-closed: shows the closed set of nodes, represented by \'o\'");
                writeln("\t--show-open: shows the open set of nodes, represented by \'x\'");
                writeln("\t--manhattan: used manhattan distance for heuristic");
                writeln("\t--euclidean: used euclidean distance for heuristic");
                return 1;
            break;
            case "--diagonal":
                uflag |= SolveFlags.DIAGONAL;
            break;
            case "--horizontal":
                uflag |= SolveFlags.HORIZONTAL;
            break;
            case "--break-ties":
                uflag |= SolveFlags.TIE_BREAKER;
            break;
            case "--size":
                try
                {
                    SIZE = to!int(args[i + 1]);
                }
                catch (ConvException)
                {
                    writeln("[error] \'", args[i + 1], "\' is not a number");
                    return 1;
                }
                //skip the next argument
                i += 1;
                mode = 0;
            break;
            case "--file":
                file = args[i + 1];
                if (exists(file) == false)
                {
                    writeln("[error] file does not exist");
                    return 1;
                }
                i += 1;
                mode = 1;
            break;
            case "--show-closed":
                showClosed = true;
            break;
            case "--show-open":
                showOpen = true;
            break;
            case "--manhattan":
            //yes i know this is pointless
                uh = 1;
            break;
            case "--euclidean":
                uh = 2;
            break;
        }
    }
    if (mode == cast(uint)-1)
    {
        writeln("[error] no solve mode provided");
        return 1;
    }
    if (SIZE <= 1 && mode == 0)
    {
        writeln("[error] invalid range");
        return 1;
    }
    Field field = new Field(SIZE, SIZE, ' ', ' ');
    int width = 0, height = 0, exp = 0;
    Node start, end;
    if (mode == 1)
    {
        field.reset();
        File* maze = new File(file, "r");
        string push;
        while ((push = maze.readln()) !is null)
        {
            field.pushln(push[0..$ - 1]);
            if (push.length - 1 > width)
                width = cast(int)push.length - 1;
            foreach (i; 0..push.length - 1)
            {
                char c = push[i];
                if (c == '@')
                {
                    start = new Node(cast(int)i, height, 0.0, 0.0, 0.0);
                }
                else if (c == 'X')
                {
                    end = new Node(cast(int)i, height, 0.0, 0.0, 0.0);
                }
                else if (c == ' ')
                {
                    exp++;
                }
            }
            height++;  
        }
    }
    else
    {
        start = new Node(0, 0, 0.0, 0.0, 0.0);
        end = new Node(SIZE - 1, SIZE - 1, 0.0, 0.0, 0.0);
        width = SIZE;
        height = SIZE;
        exp = pow(SIZE, 2);
    }
    writeln(start);
    writeln(end);
    StopWatch sw;
    sw.start();
    auto fastestPath = Astar(start, end, width, height, field, exp, uflag);
    sw.stop();
    if (fastestPath.length == 0)
    {
        writeln("[error] no solution");
        return 1;
    }
    writeln('\n');
    foreach(n; fastestPath[1..$-1].parallel)
    {
       //writeln(n);
       field.replace(n, '*');
    }
    
    writeln();
    writeln(field);
    writeln("solved maze in ", sw.peek.total!"msecs", "ms");
    
    version (stacktest)
    {
        writeln("Node stack testing");
        NodeStack stack = new NodeStack();
        stack.insert(new Node(5, 2, 0.0, 0.0, 5.0));
        stack.insert(new Node(0, 0, 0.0, 0.0, 0.0));
        stack.insert(new Node(1, 1, 0.0, 0.0, 1.0));
        stack.insert(new Node(2, 2, 0.0, 0.0, 2.0));
        stack.insert(new Node(3, 2, 0.0, 0.0, 3.0));
        stack.insert(new Node(4, 2, 0.0, 0.0, 4.0));

        writeln(stack);
        writeln(stack.take(3, 0));
        stack.pop();
        stack.pop();
        stack.pop(2);
        writeln(stack);
        stack.insert([new Node(0, 0, 0.0, 0.0, 0.0),
                        new Node(1, 1, 0.0, 0.0, 1.0),
                        new Node(4, 2, 0.0, 0.0, 4.0)]);
        writeln(stack);
    }
    version (settest)
    {
        writeln("Node set testing");
        NodeSet set = new NodeSet();
        set.insert(new Node(5, 2, 0.0, 0.0, 5.0));
        set.insert(new Node(0, 0, 0.0, 0.0, 0.0));
        set.insert(new Node(1, 1, 0.0, 0.0, 1.0));
        set.insert(new Node(2, 2, 0.0, 0.0, 2.0));
        set.insert(new Node(3, 2, 0.0, 0.0, 3.0));
        set.insert(new Node(4, 2, 0.0, 0.0, 4.0));
        set.insert(new Node(5, 2, 0.0, 0.0, 5.0));
        uint cnt = 0;
        foreach(n; set)
        {
            writeln("Node: ", n, " -- count: ", cnt++);
        }
        cnt = 0;
        writeln("a second time");
        foreach(n; set)
        {
            writeln("Node: ", n, " -- count: ", cnt++);
            if (cnt == 3)
            {
                writeln("breaking loop...");
                break;
            }
        }
        cnt = 0;
        writeln("a third time");
        foreach(n; set)
        {
            writeln("Node: ", n, " -- count: ", cnt++);
        }
    }

    return 0;
}