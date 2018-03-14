import std.stdio: writeln;
import std.container.array: Array;
import std.math: sqrt, abs, pow;
import std.container.binaryheap: BinaryHeap;
import std.format: format;
import std.datetime.stopwatch: StopWatch;
import std.conv: to;


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
    
    double result = abs(sqrt(cast(float)pow(current.x - end.x, 2) + cast(float)pow(current.y - end.y, 2)));
    if (breakTies == true)
    {
        //tie-breaker
        /*http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html#breaking-ties*/
        int dx1 = current.x - end.x;
        int dy1 = current.y - end.y;
        int dx2 = start.x - end.x;
        int dy2 = start.y - end.y;
        double cross = abs(dx1*dy2 - dx2*dy1);
        return result + (cross*0.001);
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

bool exists(Array!Node nodes, Node n)
{
    foreach (tmp; nodes)
        if (n.x == tmp.x && n.y == tmp.y)
            return true;
    return false;
}

Node getBestNode(ref NodeStack stack, Array!Node closed)
{
    bool valid = false;
    Node bestNode;
    do
    {
        bestNode = stack.popFront();
        if (closed.exists(bestNode) == false)
            valid = true;
    } while (valid == false);
    return bestNode;
}

Node getBestNode(ref BinaryHeap!(Node[]) heap, Array!Node closed)
{
    bool valid = false;
    Node bestNode;
    do
    {
        bestNode = heap.front();
        if (closed.exists(bestNode) == false)
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
    this(int width, int height, char whitespace)
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

Array!Node Astar(Node start, Node end, int width, int height,
                 uint flags = SolveFlags.HORIZONTAL | SolveFlags.DIAGONAL | SolveFlags.TIE_BREAKER)
{
    //BinaryHeap!(Node[]) open = BinaryHeap!(Node[])([]);
    NodeStack open = new NodeStack();
    Array!Node closed;
    StopWatch lt;
    open.insert(start);
    while (open.length != 0)
    {
        lt.start();
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
                return path;
            }
            else if (n.x >= 0 && n.x <= width && n.y >= 0 && n.y <= height && closed.exists(n) == false)
            {
                //TODO: store modification. Replace nodes with same x & y values but lower f values
                //if (closed.exists(n) == false)
                open.insert(n);
            }
        }
        closed.insertBack(q);
        lt.stop();
        lt.reset();
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
    Node popFront()
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
private:
    Node[] stack;
}

int main(string[] args)
{
    if (args.length <= 1)
    {
        writeln("please enter test size");
        return 1;
    }
    uint uflag = 0;
    if (args.length == 2)
        uflag = SolveFlags.HORIZONTAL | SolveFlags.TIE_BREAKER | SolveFlags.DIAGONAL;
    else
    {
        foreach (arg; args[2..$])
        {
            switch (arg)
            {
            default: break;
            case "--break-ties":
                uflag |= SolveFlags.TIE_BREAKER;
            break;
            case "--diagonal":
                uflag |= SolveFlags.DIAGONAL;
            break;
            case "--horizontal":
                uflag |= SolveFlags.HORIZONTAL;
            break;
            }
        }
    }
    const int SIZE = to!int(args[1]);
    Node start = new Node(0, 0, 0.0, 0.0, 0.0);
    Node end = new Node(SIZE - 1, SIZE - 1, 0.0, 0.0, 0.0);
    StopWatch sw;
    sw.start();
    auto fastestPath = Astar(start, end, SIZE, SIZE, uflag);
    sw.stop();
    writeln('\n');
    Field field = new Field(SIZE, SIZE, '.');
    foreach(n; fastestPath)
    {
       writeln(n);
       field.replace(n, 'X');
    }
    
    writeln();
    writeln(field);
    writeln("solved maze in ", sw.peek.total!"msecs", "ms");
    
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
    stack.popFront();
    stack.popFront();
    stack.pop(2);
    writeln(stack);
    stack.insert([new Node(0, 0, 0.0, 0.0, 0.0),
                    new Node(1, 1, 0.0, 0.0, 1.0),
                    new Node(4, 2, 0.0, 0.0, 4.0)]);
    writeln(stack);

    return 0;
}