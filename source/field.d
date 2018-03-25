module field;
import node;
import defs;
import std.stdio;
import colorize;

//used for outputting result and checking if its possible to move to certain places
class Field
{
public:
    //construct a field of a given width and height, with what the whitespace will be made of and what character can be moved to
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
    //display the field
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
                            cwrite(("" ~ c).color(fg.init));
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
    //replace a node with a certain character
    void replace(Node n, char x)
    {
        this.field[n.y][n.x] = x;
    }
    //add a line to the field
    void pushln(string ln)
    {
        char[] build;
        foreach (c; ln)
            build ~= c;
        this.field ~= build;
    }
    //reset the field to being empty
    void reset()
    {
        this.field = [][];
    }
    //check if we can move to a certain coordinate
    bool movable(Node n)
    {
        if (n.x >= 0 && n.x < this.field[0].length && n.y >= 0 && n.y < this.field.length)
            return this.field[n.y][n.x] == mov;
        return false;
    }
private:
    //width and height of the field
    int width, height;
    //what character we can move to
    char mov;
    //array containing field
    char[][] field;
}