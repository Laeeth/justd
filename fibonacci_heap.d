module fibonacci_heap;

struct Node(V)
{
public:
    struct FibonacciHeap(V);

    inout(Node*) getPrev() inout { return prev; }
    inout(Node*) getNext() inout { return next; }
    inout(Node*) getChild() inout { return child; }
    inout(Node*) getParent() inout { return parent; }

    V getValue() const { return value; }

    bool isMarked() const { return marked; }

    bool hasChildren() const { return child !is null; }
    bool hasParent() const { return parent !is null; }
private:
    Node* prev;
    Node* next;
    Node* child;
    Node* parent;
    V value;
    int degree;
    bool marked;
};

struct FibonacciHeap(V)
{
    alias N = Node!V;

protected:
    N* heap = null;             // root node

public:

    // this()
    // {
    //     heap = _empty();
    // }

    /*virtual*/ ~this()
    {
        if (heap)
        {
            _deleteAll(heap);
        }
    }

    N* insert(V value)
    {
        N* ret = _singleton(value);
        heap = _merge(heap, ret);
        return ret;
    }

    void merge(FibonacciHeap other)
    {
        heap = _merge(heap, other.heap);
        other.heap = _empty();
    }

    bool empty() const
    {
        return heap is null;
    }

    V getMinimum()
    {
        return heap.value;
    }

    V removeMinimum()
    {
        N* old = heap;
        heap = _removeMinimum(heap);
        V ret = old.value;
        delete old;
        return ret;
    }

    void decreaseKey(N* n, V value)
    {
        heap = _decreaseKey(heap, n, value);
    }

    N* find(V value)
    {
        return _find(heap, value);
    }
private:
    N* _empty()
    {
        return null;
    }

    N* _singleton(V value)
    {
        N* n = new N;
        n.value = value;
        n.prev = n.next = n;
        n.degree = 0;
        n.marked = false;
        n.child = null;
        n.parent = null;
        return n;
    }

    N* _merge(N* a, N* b)
    {
        if (a is null) return b;
        if (b is null) return a;
        if (a.value > b.value)
        {
            N* temp = a;
            a = b;
            b = temp;
        }
        N* an = a.next;
        N* bp = b.prev;
        a.next = b;
        b.prev = a;
        an.prev = bp;
        bp.next = an;
        return a;
    }

    void _deleteAll(N* n)
    {
        if (n !is null)
        {
            N* c = n;
            do {
                N* d = c;
                c = c.next;
                _deleteAll(d.child);
                delete d;
            } while(c !is n);
        }
    }

    void _addChild(N* parent, N* child)
    {
        child.prev = child.next = child;
        child.parent = parent;
        parent.degree++;
        parent.child = _merge(parent.child, child);
    }

    void _unMarkAndUnParentAll(N* n)
    {
        if (n is null) return;
        N* c = n;
        do
        {
            c.marked = false;
            c.parent = null;
            c = c.next;
        }
        while (c !is n);
    }

    N* _removeMinimum(N* n)
    {
        _unMarkAndUnParentAll(n.child);
        if (n.next == n)
        {
            n = n.child;
        } else {
            n.next.prev = n.prev;
            n.prev.next = n.next;
            n = _merge(n.next, n.child);
        }
        if (n is null) return n;
        N*[64] trees; // = { null };

        while(true)
        {
            if (trees[n.degree] !is null)
            {
                N* t = trees[n.degree];
                if (t == n) break;
                trees[n.degree] = null;
                if (n.value < t.value)
                {
                    t.prev.next = t.next;
                    t.next.prev = t.prev;
                    _addChild(n, t);
                }
                else
                {
                    t.prev.next = t.next;
                    t.next.prev = t.prev;
                    if (n.next == n)
                    {
                        t.next = t.prev = t;
                        _addChild(t, n);
                        n = t;
                    }
                    else
                    {
                        n.prev.next = t;
                        n.next.prev = t;
                        t.next = n.next;
                        t.prev = n.prev;
                        _addChild(t, n);
                        n = t;
                    }
                }
                continue;
            } else {
                trees[n.degree] = n;
            }
            n = n.next;
        }
        N* min = n;
        do {
            if (n.value < min.value) min = n;
            n = n.next;
        } while (n !is n);
        return min;
    }

    N* _cut(N* heap, N* n)
    {
        if (n.next == n)
        {
            n.parent.child = null;
        } else {
            n.next.prev = n.prev;
            n.prev.next = n.next;
            n.parent.child = n.next;
        }
        n.next = n.prev = n;
        n.marked = false;
        return _merge(heap, n);
    }

    N* _decreaseKey(N* heap, N* n, V value)
    {
        if (n.value < value) return heap;
        n.value = value;
        if (n.value < n.parent.value)
        {
            heap = _cut(heap, n);
            N* parent = n.parent;
            n.parent = null;
            while(parent !is null && parent.marked)
            {
                heap = _cut(heap, parent);
                n = parent;
                parent = n.parent;
                n.parent = null;
            }
            if (parent !is null && parent.parent !is null) parent.marked = true;
        }
        return heap;
    }

    N* _find(N* heap, V value)
    {
        N* n = heap;

        if (n is null) return null;

        do
        {
            if (n.value == value) return n;
            N* ret = _find(n.child, value);
            if (ret) return ret;
            n = n.next;
        }
        while (n !is heap);

        return null;
    }
};

void dumpDot(V)(ref FibonacciHeap!V _fh)
{
    import std.stdio: writeln, writefln;

    writeln(`digraph G {`);
    if (_fh.heap is null)
    {
        writeln(`empty;\n}`);
        return;
    }
    writefln(`minimum -> "%x" [constraint = false];`, _fh.heap);
    Node!int* c = _fh.heap;

    do
    {
        dumpDotChildren(c);
        c = c.getNext();
    }
    while (c !is _fh.heap);

    writeln(`}`);
}

void dumpDotChildren(ref Node!int* n)
{
    import std.stdio: writeln, writefln;

    writefln(`"%x" -> "%x" [constraint = false, arrowhead = lnormal];`, n, n.getNext());
    writefln(`"%x" -> "%x" [constraint = false, arrowhead = ornormal];`, n, n.getPrev());

    if (n.isMarked())
        writefln(`"%x" [style = filled, fillcolor = grey];`, n);

    if (n.hasParent())
    {
        writefln(`"%x" -> "%x" [constraint = false, arrowhead = onormal];`, n, n.getParent());
    }

    writefln(`"%x" [label = %d];`, n, n.getValue());

    if (n.hasChildren())
    {
        Node!int* c = n.getChild();
        do
        {
            writefln(`"%x" -> "%x";`, n,c);
            dumpDotChildren(c);
            c = c.getNext();
        }
        while (c !is n.getChild());
    }
}

// Write output to file X and process it with: "dot -O -Tsvg X"
unittest
{
    FibonacciHeap!int h;

    h.insert(2);
    h.insert(3);
    h.insert(1);
    h.insert(4);

    h.removeMinimum();
    h.removeMinimum();

    h.insert(5);
    h.insert(7);

    h.removeMinimum();

    h.insert(2);

    Node!int* nine = h.insert(90);

    h.removeMinimum();
    h.removeMinimum();
    h.removeMinimum();

    for (int i = 0; i < 20; i += 2)
        h.insert(30-i);
    for (int i = 0; i < 4; i++)
        h.removeMinimum();
    for (int i = 0; i < 20; i+= 2)
        h.insert(30-i);

    h.insert(23);

    for (int i = 0; i < 7; i++)
        h.removeMinimum();

    h.decreaseKey(nine, 1);
    h.decreaseKey(h.find(28), 2);
    h.decreaseKey(h.find(23), 3);

    h.dumpDot();
}
