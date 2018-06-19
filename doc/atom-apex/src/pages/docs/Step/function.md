---
title: "Function"
description: "Function"
layout: "guide"
icon: "code-file"
weight: 3
---

###### {$page.description}

<article id="1">

## Atom Function

Atom.apex provides helper functions to wrap existing functions.

</article>

<article id="2">

## compute

Compute the given Func with arguments from the state and set the value back

```javascript
Func f = Atom.F.compute.apply('count', R.inc, 'count');
// Get the 'count', increment it and set the value back to 'count'

Func f = Atom.F.compute.apply(R.inc, 'count');
// Get the 'count', increment it and do not set it back
```

</article>
