---
title: "State"
description: "State"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 6
---

## {$page.title}

An Atom holds a state, which is then shared by all of its steps. You can access data with the state.

```javascript
public class CustomCompute extends Atom.Compute {
    public override void execute(Atom.State s) {
        Integer count = (Integer)s.getData('count');
        count += 1;
        s.setData('count', count);
    }
}
```

And this is the only way to communicate with other steps in Atom.apex
