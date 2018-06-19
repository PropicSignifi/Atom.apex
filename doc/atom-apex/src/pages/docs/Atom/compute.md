---
title: "Compute"
description: "Compute"
layout: "guide"
icon: "flash"
weight: 2
---

###### {$page.description}

<article id="1">

## What is a Compute?

A compute is the basic unit of you business logic, the building blocks.

Most of the time, you will group your code into computes and then chain them into Atoms.

A compute should be planned carefully so that it runs within the governor limits. To make it
simple, double check that no loops are used with a possible large dataset.

</article>

<article id="2">

## Custom Compute

You can create a custom compute.

```javascript
public class CustomCompute extends Atom.Compute {
    public override void execute(Atom.State s) {
        Integer count = (Integer)s.getData('count');
        count += 1;
        s.setData('count', count);
    }
}
```

Bear in mind that computes run in queueable jobs, and they should interact only with Atom states.

</article>

<article id="3">

## Func Compute

Atom.apex offers `FuncCompute` to help wrap functions into computes.

Here is an example:

```javascript
new Atom()
    .then(new Atom.FuncCompute(R.debug.apply('test')))
    .fork();
```

In fact, this is usually simplified into this:

```javascript
new Atom()
    .then(R.debug.apply('test'))
    .fork();
```

</article>
