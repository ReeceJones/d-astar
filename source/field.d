module field;
import node;
import defs;
import std.stdio;
import colorize;

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
    void display()
    {
        foreach (s; this.field)
        {
            if (col == true)
            {
                foreach (c; s)
                {
                    switch (c)
                    {
                        default:
                            cwrite(("" ~ c).color(fg.init, bg.init, mode.bold));
                        break;
                        case cp:
                            cwrite(("" ~ c).color(fg.light_red));
                        break;
                        case cc:
                            cwrite(("" ~ c).color(fg.light_green));
                        break;
                        case co:
                            cwrite(("" ~ c).color(fg.light_blue));
                        break;
                    }
                }
                writeln();
            }
            else
                writeln(s);
        }
    }
    /*override string toString()
    {
        string ret;
        version (Windows)
        {
            if (col == true)
                writeln("[warning] color is not supported on windows");

        }
        foreach (s; this.field)
        {
            foreach (c; s)
            {
                version (OSX)
                {
                    if (col == true)
                    {
                        if (c == cp)
                        {
                            ret ~= "\x1b[91m\x1b[100m";
                        }
                        else if (c == cc)
                        {
                            ret ~= "\x1b[92m\x1b[100m";
                        }
                        else if (c == co)
                        {
                            ret ~= "\x1b[94m\x1b[100m";
                        }
                    }
                }
                version (linux)
                {
                    if (col == true)
                    {
                        if (c == cp)
                        {
                            ret ~= "\x1b[91m\x1b[100m";
                        }
                        else if (c == cc)
                        {
                            ret ~= "\x1b[92m\x1b[100m";
                        }
                        else if (c == co)
                        {
                            ret ~= "\x1b[94m\x1b[100m";
                        }
                    }
                }
                ret ~= c;
                version (OSX)
                    if ((c == cp || c == cc || c == co) && col == true)
                        ret ~= "\x1b[0m";
                version (linux)
                    if ((c == cp || c == cc || c == co) && col == true)
                        ret ~= "\x1b[0m";
            }
            ret ~= '\n';
        }
        return ret;
    }*/
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