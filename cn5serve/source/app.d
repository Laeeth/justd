#!/usr/bin/env rdmd-dev

import vibe.http.router;
import vibe.http.server;
import vibe.web.web;

shared static this()
{
    auto router = new URLRouter;
    router.registerWebInterface(new WebInterface);

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.sessionStore = new MemorySessionStore;
    listenHTTP(settings, router);
}

class WebInterface {
    private {
        // stored in the session store
        SessionVar!(bool, "authenticated") ms_authenticated;
    }

    // GET /
    void index()
    {
        bool authenticated = ms_authenticated;
        render!("index.dt", authenticated);
    }

    // POST /login  (username and password are automatically read as form fields)
    void postLogin(string username, string password)
    {
        enforceHTTP(username == "user" && password == "secret",
                    HTTPStatus.forbidden, "Invalid user name or password.");
        ms_authenticated = true;
        redirect("/");
    }

    // POST /logout
    @method(HTTPMethod.POST) @path("logout")
    void postLogout()
    {
        ms_authenticated = false;
        terminateSession();
        redirect("/");
    }
}

import conceptnet5;

void loadCN5()
{
    import std.stdio;
    // TODO Add auto-download and unpack from http://conceptnet5.media.mit.edu/downloads/current/

    auto net = new Net!(true, false)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
    net.showConcepts(`car`);
    net.showConcepts(`car_wash`);

    while (true)
    {
        write(`Lookup: `); stdout.flush;
        string line;
        if ((line = readln()) !is null)
        {
            net.showConcepts(line);
        }
        else
        {
            break;
        }
    }
    /* if (true) */
    /* { */
    /*     auto netPack = net.pack; */
    /*     writeln(`Packed to `, netPack.length, ` bytes`); */
    /* } */

    if (false) // just to make all variants of compile
    {
        /* auto netH = new Net!(!useHashedStorage)(`~/Knowledge/conceptnet5-5.3/data/assertions/`); */
    }

    write(`Press enter to continue: `);
    readln();
}
