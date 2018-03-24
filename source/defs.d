module defs;

//flag stuff
bool showClosed = false;
bool showOpen = false;
bool col = false;
uint uh = 0;

enum SolveFlags
{
    NONE = 0,
    HORIZONTAL = (1 << 0),
    DIAGONAL = (1 << 1),
    TIE_BREAKER = (1 << 2),
}

//display stuff
immutable char cp = '*';
immutable char cc = 'o';
immutable char co = 'x';
