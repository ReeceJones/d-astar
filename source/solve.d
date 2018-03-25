import std.stdio;
import std.container.array: Array;
import std.math: sqrt, abs, pow;
import std.container.binaryheap: BinaryHeap;
import std.format: format;
import std.datetime.stopwatch: StopWatch;
import std.conv: to, ConvException;
import std.file: exists;
import std.parallelism: parallel;
import node;
import defs;
import nodecontainers;
import field;
//lots of imports

//check to see if a node exists in a given array
bool nodeExists(Array!Node nodes, Node n)
{
    foreach (tmp; nodes)
        if (n.x == tmp.x && n.y == tmp.y)
            return true;
    return false;
}

//get the best node in a nodestack
Node getBestNode(ref NodeStack stack, ref NodeSet closed)
{
    bool valid = false;
    Node bestNode;
    do
    {
        //remove the best node and assign it to bestNode
        bestNode = stack.pop();
        //check to see if it exists in the closed set
        if (closed.nodeExists(bestNode) == false)
            valid = true;
    } while (valid == false);
    return bestNode;
}

//get successors to a given node position
Array!Node getSuccessors(Node current, Node start, Node end, uint flags)
{
    Array!Node successors;
    //lambda for easily adding nodes to an array
    static auto push = function(ref Array!Node a, Node n) => a.insertBack(n);
    //whether or not to break ties
    bool breakTies = !(flags & SolveFlags.TIE_BREAKER) == 0;
    //if we can move up, left, right, down
    if (flags & SolveFlags.HORIZONTAL)
    {
        push(successors, new Node(current.x + 1, current.y, current, end, start, breakTies));
        push(successors, new Node(current.x - 1, current.y, current, end, start, breakTies));
        push(successors, new Node(current.x, current.y + 1, current, end, start, breakTies));
        push(successors, new Node(current.x, current.y - 1, current, end, start, breakTies));
    }
    //if the diagonal flag is set
    if (flags & SolveFlags.DIAGONAL)
    {
        push(successors, new Node(current.x + 1, current.y + 1, current, end, start, breakTies));
        push(successors, new Node(current.x - 1, current.y - 1, current, end, start, breakTies));
        push(successors, new Node(current.x - 1, current.y + 1, current, end, start, breakTies));
        push(successors, new Node(current.x + 1, current.y - 1, current, end, start, breakTies));
    }
    return successors;
}

//solve a maze using the a* algorithm
Array!Node Astar(Node start, Node end, int width, int height, ref Field field, uint expected,
                 uint flags = SolveFlags.HORIZONTAL | SolveFlags.DIAGONAL | SolveFlags.TIE_BREAKER)
{
    //open set containing nodes that are being considered
    NodeStack open = new NodeStack();
    //closed set containing nodes we've traveled to
    NodeSet closed = new NodeSet();
    //we need a starting point, so why don't we start at the start
    open.insert(start);
    //if there are no nodes left being considered there is no path
    while (open.length != 0)
    {
        //q is the best node in the open set
        Node q = getBestNode(open, closed);
        //get potential nodes
        Array!Node successors = getSuccessors(q, end, start, flags);
        //iterate the successors and insert them into the open set
        foreach(n; successors)
        {
            //if a successor is the end we want to travel to it
            if (n.x == end.x && n.y == end.y)
            {
                //trace back the best path
                Array!Node path;
                Node tmp = n;
                path.insertBack(tmp);
                do
                {
                    tmp = tmp.parent;
                    path.insertBack(tmp);
                } while (tmp.parent !is null);
                if (showClosed == true)
                    foreach (z; closed)
                        field.replace(z, co);
                if (showOpen == true)
                    foreach(z; open)
                        field.replace(z, cc);
                //just some statistics
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
        //a quick shortcut for making sure that we don't get stuck
        if (closed.length == expected)
        {
            //return an empty array if we cannot find a path
            return Array!Node();
        }
    }
    //return an empty array
    return Array!Node();
}

int main(string[] args)
{
    //testing the stack and set containers
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

    //variables used to solve the maze
    uint uflag = 0;
    uint mode = -1;
    int SIZE;
    string file;
    //get what the user wants to do with the maze
    version (standalone)
    {
        write("mode (size/file): ");
        string type;
        readf!"%s\n"(type);
        if (type == "size")
            mode = 0;
        else if (type == "file")
            mode = 1;
        else
        {
            writeln("[error] invalid input");
            return 1;
        }
        string sz = mode == 1 ? "file: " : "size: ";
        write(sz);
        readf!"%s\n"(sz);
        if (mode == 1)
        {
            file = sz;
            if (exists(file) == false)
            {
                writeln("[error] file does not exist");
                return 1;
            }
        }
        else
        {
            try
            {
                SIZE = to!int(sz);
            }
            catch (ConvException)
            {
                writeln("[error] \'", sz, "\' is not a number");
                return 1;
            }
        }
        write("movable to (horizontal/diagonal/both): ");
        string mov;
        readf!"%s\n"(mov);
        switch (mov)
        {
            default:
            writeln("[error] \'" ~ mov ~ "\' unrecognized");
            return 1;
            case "horizontal":
                uflag |= SolveFlags.HORIZONTAL;
            break;
            case "diagonal":
                uflag |= SolveFlags.DIAGONAL;
            break;
            case "both":
                uflag |= SolveFlags.HORIZONTAL | SolveFlags.DIAGONAL;
            break;
        }
        write("heuristic (dijkstra/euclidean/manhattan): ");
        string hs;
        readf!"%s\n"(hs);
        switch (hs)
        {
            default:
            writeln("[error] \'" ~ hs ~ "\' unrecognized");
            return 1;
            case "dijkstra:":
                uh = 2;
            break;
            case "euclidean":
                uh = 2;
            break;
            case "manhattan":
                uh = 1;
            break;
        }
        write("show extras (none/show closed/show open/both): ");
        string sh;
        readf!"%s\n"(sh);
        switch (sh)
        {
            default:
            writeln("[error] \'" ~ sh ~ "\' unrecognized");
            return 1;
            case "show open:":
                showOpen = true;
            break;
            case "show closed":
                showClosed = true;
            break;
            case "both":
                showOpen = true;
                showClosed = true;
            break;
            case "none":
                showOpen = false;
                showClosed = false;
            break;
        }
        write("color (yes/no): ");
        string co;
        readf!"%s\n"(co);
        switch (co)
        {
            default:
            writeln("[error] \'" ~ co ~ "\' unrecognized");
            return 1;
            case "yes":
                col = true;
            break;
            case "no":
                col = false;
            break;
        }
        write("break ties (yes/no): ");
        string bt;
        readf!"%s\n"(bt);
        switch (bt)
        {
            default:
            writeln("[error] \'" ~ bt ~ "\' unrecognized");
            return 1;
            case "yes":
                uflag |= SolveFlags.TIE_BREAKER;
            break;
            case "no":
            break;
        }
    }
    else
    {
        if (args.length <= 1)
        {
            writeln("[error] no parameters provided");
            return 1;
        }
        for (uint i = 1; i < args.length; i++)
        {
            switch (args[i])
            {
                default:
                    writeln("[error] \'", args[i], "\' unrecognized");
                return 1;
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
                    writeln("\t--color: use color for output");
                return 1;
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
                case "--color":
                    col = true;
                break;
            }
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
    //create a new field
    Field field = new Field(SIZE, SIZE, ' ', ' ');
    int width = 0, height = 0, exp = 0;
    Node start, end;
    //we have to find the starting and end point in the maze
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
       field.replace(n, cp);
    }
    
    writeln();
    field.display();
    writeln("solved maze in ", sw.peek.total!"msecs", "ms");
    
    version (standalone)
    {
        //let the user see the output. they have to press enter to end the program
        readln();
    }

    return 0;
}
