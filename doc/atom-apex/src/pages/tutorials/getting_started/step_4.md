---
title: "Compute"
description: "Compute"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 4
---

## {$page.title}

A **compute** is a single unsplittable unit of business logic that can be executed within a transaction. In Atom.apex, all steps are running in the queueable job context, so the Async Apex Limits apply here.

Here is how we create a `CustomCompute`.

```javascript
public class CustomCompute extends Atom.Compute {
    public override void execute(Atom.State s) {
        Integer count = (Integer)s.getData('count');
        count += 1;
        s.setData('count', count);
    }
}
```
