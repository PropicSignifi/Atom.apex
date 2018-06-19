---
title: "Functional Support"
description: "Functional Support"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 8
---

## {$page.title}

Atom.apex embraces functional style programming. You can pass in a Func to be used as a Compute or a Step.

```javascript
new Atom()
    .then(R.debug.apply('Running'))
    .fork();
```

Atom.apex has a helper Func to get values from the state, provide them to the given Func and apply the computed value back to the state.

```javascript
new Atom()
    .then(Atom.F.compute.apply('count', R.inc, 'count'))
    .fork();
```

The code above will get the number indexed by `count`, increment it and set it back to `count`.

If a Func returns `true` without being set to the state, the interrupted flag will be marked.

```javascript
new Atom()
    .then(Atom.F.compute.apply(R.equals.apply(1), 'count'))
    .fork();
```

This code will request an interruption if the count equals with 1.
