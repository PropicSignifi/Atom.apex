---
title: "State"
description: "State"
layout: "guide"
icon: "code-file"
weight: 2
---

###### {$page.description}

<article id="1">

## State

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

</article>

<article id="2">

## Reference

| Method | Description |
| ------ | ----------- |
| Map&lt;String, Object&gt; all() | Get all the data |
| Object getData(String) | Get the data by the key |
| void setData(String, Object) | Set the data by the key and value |
| Boolean isInterrupted() | Check if it is interrupted |
| void setInterrupted(Boolean) | Set whether it is interrupted |
| Integer getInterruptedTimes() | Get the interrupted times |

</article>
