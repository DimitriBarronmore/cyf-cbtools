# Coroutine Bullet Tools

A collection of small helper functions intended to make it easier to create complex bullet patterns and animations.

For an example of how to use CBTools to build a simple warning->attack wave, see example.lua

**Setup Instructions:**

**0).** Copy cbtools.lua to a desirable place in your mod.

**1).** Run **`cbtools = require("cbtools")`** to load the library.

**2).** Ensure that **`cbtools.update`** is running in the script's Update() function.

-----------------------

## **Features:**

**`cbtools.waitFor(duration, seconds = false)`**
Execution pauses, continuing on the `duration`th frame afterwards.
If `seconds` is true, it instead continues after at least `duration` seconds have passed.

**`cbtools.waitUntil(condition)`**
`condition` must be a function which returns a value. 
Execution pauses, immediately resuming when `condition` returns `true`.
If `condition` immediately returns `true`, execution continues on the same frame.

**`cbtools.doFor(count, function)`**
Executes `function` `count` times, pausing between frames.
For example, if `cbtools.doFor(5, my_func)` is called on frame one, `my_func` will run on frames 1-5.

**`cbtools.doUntil(condition, function)`**
Similar to `cbtools.waitUntil`; continuously executes `function` until `condition` returns true, pausing between frames.
If `condition` immediately returns `true`, then `function` is never run and execution continues as normal.

**`coroutine = cbtools.queue(function, name, ...)`**
Creates/returns a coroutine using `function` and adds it to the queue to be resumed each frame. This enables you to easily cause multiple sequences/animations to play simultaniously without needing to manage them manually.

Due to a flaw with CYF, errors which happen inside a coroutine do not have line numbers. Instead, errors are traced using the value of `name`. If no name is provided, CBTools attempts to find an appropriate name for the function; if none are found, the name will be `"<unknown>"`.

If any additional arguments are given to `cbtools.queue`, the created coroutine will immediately be resumed using those arguments.
This allows you to easily start sequences/animations using dynamic values.

**`function = cbtools.createLooping(function)`**
A bonus utility intended for animation libraries. Creates a small "functable" using `function` which will cause it to always run as a coroutine. In essence, it returns a function which works with the wait and loop functions provided by CBTools.
Every time the returned function is called, it resumes execution once. If the function previously concluded, it starts from the beginning.
Contrast to `cbtools.queue`, which runs the given function only once.

-----------------------

### An Advanced Note:
The only thing you truly need to know about Lua's coroutines to use this library is this: a coroutine is in essence a function that runs until `coroutine.yield()` is called, and then it pauses. When it's resumed later, it continues moving from that same point forwards.

The function `coroutine.status` can tell you you whether a coroutine has finished executing all the way. When one is paused and waiting to be resumed, the result is `"suspended"`. Once it has been completed, the state becomes `"dead"`. You can use this alongside `cbtools.WaitUntil` to hold off on an action until a series of other coroutines have ended; this is used in the example to end the wave at the right time.

All this library does is resume coroutines created using `cbtools.queue` every frame until they end. Every trick this library does is due to a clever use of `coroutine.yield`, which means you can make use of it yourself. I've covered what I believe to be the only truly necessary functions for the domain of CYF: everything else is up to your imagination.
