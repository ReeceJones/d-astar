module heuristics;
import std.math;
import defs;
import node;

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
    //if we are breaking ties we want to actually do it
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