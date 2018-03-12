import std.file, std.stdio, core.thread, std.container.array, std.math, std.container.binaryheap, std.format, std.parallelism, core.exception, std.datetime.stopwatch: StopWatch;


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

Node getBestNode(ref BinaryHeap!(Node[]) heap, Array!Node closed)
{
    bool valid = false;
    Node bestNode;
    do
    {
        bestNode = heap.front();
        if (closed.exists(bestNode) == true)
            heap.popFront();
        else
            valid = true;
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
    auto push = function(ref Array!Node a, Node n) => a.insertBack(n);
    bool breakTies = (flags & SolveFlags.TIE_BREAKER) == 0;
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
    BinaryHeap!(Node[]) open = BinaryHeap!(Node[])([]);
    Array!Node closed;
    try { open.insert(start); }
    catch (AssertError ex) { writeln("[error] ", ex.msg, ". Could not insert starting point."); }
    while (open.empty() == false)
    {
        Node q = getBestNode(open, closed);
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
            else if (n.x >= 0 && n.x <= width && n.y >= 0 && n.y <= height)
            {
                //TODO: store modification. Replace nodes with same x & y values but lower f values
                open.insert(n);
            }
        }
        closed.insertBack(q);
    }
    return Array!Node();
}

int main(string[] args)
{
    immutable int SIZE = 50;
    Node start = new Node(0, 0, 0.0, 0.0, 0.0);
    Node end = new Node(SIZE - 1, SIZE - 1, 0.0, 0.0, 0.0);
    StopWatch sw;
    sw.start();
    auto fastestPath = Astar(start, end, SIZE, SIZE, SolveFlags.HORIZONTAL);
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
    
    return 0;
}