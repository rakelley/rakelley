# JHFrame

## Project Status: Finished


### Github: [https://github.com/rakelley/jhframe](https://github.com/rakelley/jhframe)


### Overview
JHFrame is a PHP MVC web framework that grew out of the evolution of the
[JakkedWeb](/projects/jakkedweb) project.  I attempted to abstract and isolate
the core structural components of JakkedWeb to increased ease of testing,
change, and reuse, to allow it to be used as a standalone framework, and because
I thought it would be a useful personal growth project.


### Project Details
JHFrame is far from a microframework, but it is designed to be reasonably fast
and simple to add new routes and functionality, while still having niceties like
a basic ORM, dynamic injection of all dependencies, and good separation of
concerns between all the moving parts of your application.

This is achieved largely through an emphasis on the Repository-pattern for data
handling and Inversion of Control for all possible application parts.

Examples:

- _IoC in Dependencies_
All dependencies are automatically injected by the `ServiceLocator` service
through constructor dependencies, which handles creating and storing objects. A
class simply has to set any classes or interfaces it depends on as arguments in
its constructor, and the `ServiceLocator` uses reflection to fill those
arguments based on its class lookup table and object store.

- _IoC in Routing_
Routes in JHFrame are semantically grouped by `RouteController` class, i.e.
`/foo/bar` is route "bar" for the "foo" `RouteController` and `/foo/baz` is the
"baz" route for the "foo" `RouteController`.  Each `RouteController` is very
thin and simply defines a list of patterns matched to public methods on itself
which typically do little more than pass a `View` or `Action` name to another
service.  JHFrame's `Router` service handles parsing the current URI, matching
it to the appropriate application `RouteController`, querying the
`RouteController` for a method name matching a pattern, and calling that method.

- _IoC in Views and Actions_
Views with JHFrame are proper testable classes (though static html files are
also supported).  Actions are the class of object representing non-view API
endpoints, such as form targets.  Both follow an IoC pattern, defining which
public methods of theirs need to be called in order to complete their jobs
through a standard set of interfaces which are read through reflection by the
`ViewController` and `ActionController` services that handle the execution of
all `View`s and `Action`s.

- _Repositories_
All data access with JHFrame is done via Repositories.  A `Repository` provides
a simple API for `View`s and `Action`s to use for reading/writing data to
multiple data sources (`Model`s, `FileHandler`s, etc), as well as any necessary
sorting or other logic, without them needing to know the underlying structure.
This provides an important layer of abstraction between your route endpoints and
your data and allows you to write very simple `Model`s with only the minimal
logic necessary for their database queries and so on.


### Post-Mortem
JakkedWeb, and by extension JHFrame, are ultimately learning projects afforded
by the luxury of a low-demand client and ample time to experiment and refactor.
JHFrame is extremely solid (read: overkill) for its use case, but ultimately
has limited real-world value when there are excellent alternatives like Lumen
and Laravel for other developers.  Regardless, I consider what I learned through
its development and many changes to be invaluable experience I never would have
gained had I used a 3rd party framework as my initial starting point.  I learned
as much from what I initially did wrong as what I eventually did right.
