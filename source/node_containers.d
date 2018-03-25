module nodecontainers;
import node;

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
        //iterate through the private array of nodes
        //if we find a node with matching coordinates, but a lower f-value we will replace it
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
    //check to see if a node exists in the set
    bool nodeExists(Node n)
    {
        foreach (c; this.set)
            if (n.x == c.x && n.y == c.y)
                return true;
        return false;
    }
    //for debugging purposes
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
    //for iterating through the set using input ranges
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
    //debugging variables
    uint cnt;
    uint errcnt;

    //input range stuff
    Node n;
    uint index;
    bool hasNode, frontCheck;

    //array of nodes that makes up the set
    Node[] set;
}