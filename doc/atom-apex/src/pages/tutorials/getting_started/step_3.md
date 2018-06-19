---
title: "Big Picture"
description: "Big Picture"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 3
---

## {$page.title}

We will have an overview of what Atom.apex looks like in action.

```javascript
Map<String, Object> initialData = new Map<String, Object>{ ... };
new Atom(initialData)
    .then(new CustomBeforeCompute())
    .then(new Atom.ForEachStep('item', 'items', new CustomCompute()))
    .then(new CustomAfterCompute())
    .fork();
```

Here we split our business logic into `CustomBeforeCompute`, `CustomCompute` and `CustomAfterCompute`. The Atom instance is created with the initial data, then it will execute the `CustomBeforeCompute`. After that, it will do a 'for-each' loop of CustomCompute over the data indexed by 'items', and the looping item will be saved under the key of 'item'. Finally it will do the `CustomAfterCompute`.

All is not set off until the fork is invoked. During any step, if governor limits are reached, a new queueable job will be created to continue to run the remaining logic.
