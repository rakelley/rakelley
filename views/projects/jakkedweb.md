# JakkedWeb

## Project Status: Finished


### Github: [https://github.com/rakelley/jakkedweb](https://github.com/rakelley/jakkedweb)


### Overview
JakkedWeb is the site behind [jakkedhardcore.com](https://jakkedhardcore.com),
the business website for Jakked Hardcore Gym in Montgomery, IL.  It consists of
a public application for the primary public website as well as a full Content
Management System with user access controls to allow for the modification of the
site by employees with virtually zero technical knowledge.  Both applications
are built on [JHFrame](/projects/jhframe).


### Project Details
I was initially hired by Jakked Gym in August of 2011, and part of my new
responsibilities was modernizing and updating the website.  The site I inherited
had been cobbled together in Dreamweaver years previously and was a disaster.
All layout was done with tables, all CSS was inline, and absurd hacks were used
for whitespace (e.g. 800 1x1 transparent gifs for a 1x800px margin).  No two
pages had the same sidebar.

I had at the time no real experience with HTML or CSS and none with PHP
(the only language supported by the provided hosting), but in the first week
dove straight in and completely rewrote the site with a more modern floated
layout, consistent external CSS, and my first use of PHP (including a single
sidebar file in all pages).

After that, whenever I had spare time at work from other day to day duties, I
edited.  At first it was still mostly static HTML, just modernized and
responsive, but I was asked to make it easier for others to edit and began
making plans to develop a CMS.  I explored several existing content platforms,
but ultimately decided that it would be much more useful to develop one from
scratch due to existing options being extremely heavyweight and the lack of
urgency in the project meaning I had the opportunity to take things slow and
learn from scratch.

Over the last several years the site has gradually grown through additions and
rewrites as new features have been requested, as I have improved as a coder, and
as PHP itself has matured from the ugly step-child of the web into a faster and
more modern language with a robust ecosystem of tools.  The Jakked website is
now a mobile-friendly responsive site powered by a database and full MVC
framework ([JHFrame](/projects/jhframe)), the CMS is feature-rich and easy to
use even for employees with zero technical knowledge, all code is covered with
unit tests, and front-end tools like SASS and RequireJS have been incorporated
as well.


### Post-Mortem
While it may seem ridiculous to have spent several years at a few hours a week
making and remaking what is ultimately a low-traffic small business website,
this project has been exactly the educational opportunity I needed to develop
from an occasional tinkerer into a proper programmer, and I am extremely
grateful to have been provided it.
