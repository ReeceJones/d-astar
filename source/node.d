module node;
import std.format;
import heuristics;

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
        return _f < (cast(Node)other).f ? 1 : -1;
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