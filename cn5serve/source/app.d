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

import knet;

void loadKNet()
{
    auto net = new Net!(true, false)(`~/Knowledge/conceptnet5-5.3/data/assertions/`);
}
