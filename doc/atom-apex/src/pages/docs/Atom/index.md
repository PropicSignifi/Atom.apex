---
title: "Atom"
description: "Atom"
layout: "guide"
icon: "flash"
weight: 1
---

###### {$page.description}

<article id="1">

## What is an Atom?

An atom is originally an unsplittable unit. In Atom.apex, we refer it as a piece of business logic
that gets executed even when governor limits are reached.

Usually when we reach the governor limits(heap size, cpu time, query, ...), it is because we are repeating a resource-consuming action. Everything works when there is reasonable repetition. But the unexpected data may cause the repetition count to grow out of control. By then, the governor limits are reached, exceptions are thrown, business logic is aborted and you are left in a mess(especially when you interact with external services).

What we have dreamed is that if the governor limits are reached, Salesforce does not throw exceptions directly, and instead it will schedule our remaining logic to the next available time spot to continue.

Sadly this has always been a dream and Salesforce aborts your execution brutally in this case(roll back your transaction as well, which is a good thing).

This is how we got our inspiration. We want to **split** our business logic into **steps**, so that each step can be executed sequentially and if resources are running out, we have a chance to save our progress and then continue the remaining steps.

We call the whole process an **Atom**, which means that your business logic is guaranteed to be executed even if some governor limits are reached, so that it will not be broken.

</article>

<article id="2">

## How is Atom implemented?

In essence, an Atom is just a chain of queueable jobs in Apex.

We split an Atom instance into steps, and each step is executed one after another. Every time a step is executed,
Atom.apex will check if the governor limits are reached. If so, Atom.apex will stop executing, save the current data and start
a new queueable job to continue the remaining code.

</article>

<article id="3">

## How should Atom be used?

Atom.apex should be used when there is the need to handle scalable code execution that may break the governor limits.

So it should be used at the entry point of the execution context. Also it uses chained queueable jobs to execute the code,
which means that it cannot be used in a synchronous context.

Here is the outline of the usage.

```javascript
Map<String, Object> initialData = new Map<String, Object>{ ... };
new Atom(initialData)
    .then(new CustomBeforeCompute())
    .then(new Atom.ForEachStep('item', 'items', new CustomCompute()))
    .then(new CustomAfterCompute())
    .fork();
```

</article>

<article id="4">

## Constructors

| Constructor | Description |
| ------ | ----------- |
| Atom() | Create an empty Atom |
| Atom(Map&lt;String, Object&gt;) | Create an Atom with initial data |

</article>

<article id="5">

## Methods

| Method | Description |
| ------ | ----------- |
| Atom.State getState() | Get the Atom state |
| Integer getMaxInterruptions() | Get the max interruptions |
| Atom setMaxInterruptions(Integer) | Set the max interruptions |
| Atom then(Atom.Step) | Chain the next step |
| Atom then(Atom.Compute) | Chain the next compute in a step |
| Atom then(Func f) | Chain the next Func in a step |
| Atom fork() | Execute the Atom |

</article>
