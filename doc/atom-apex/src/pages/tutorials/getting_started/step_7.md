---
title: "Interruptions"
description: "Interruptions"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 7
---

## {$page.title}

In Atom.apex, when the governor limits are reached, we try to create a new queueable job to execute the remaining logic. The attempt to switch to a new queueable job is called an interruption.

Most of the time, we do not need to request for interruptions. But if we do, we can use this.

```javascript
public class CustomCompute extends Atom.Compute {
    public override void execute(Atom.State s) {
        s.setInterrupted(true);
    }
}
```

Also notice that new queueable jobs will not fix all the governor limit issues. So we have a limit for the interruptions. When an Atom tries the limit number of interruptions and still fails to resolve the resource issue, an exception will be thrown to indicate that.

You can set the interruption limit.

```javascript
new Atom()
    .setMaxInterruptions(20)
    .then(...)
    .fork();
```
