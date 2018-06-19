/**
 * MIT License
 *
 * Copyright (c) 2018 Click to Cloud Pty Ltd
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **/
@isTest
private class AtomTest {
    @isTest
    private static void simpleStepTest() {
        Map<String, Object> data = new Map<String, Object>();
        Atom a = new Atom(data)
            .then(Atom.F.compute.apply('val', R.constant.apply('test')))
            .fork();

        System.assertEquals('test', data.get('val'));
    }

    @isTest
    private static void interruptTest() {
        Map<String, Object> data = new Map<String, Object>();
        Atom a = new Atom(data)
            .then(Atom.F.compute.apply(R.T))
            .fork();

        System.assertEquals(1, a.getState().getInterruptedTimes());
    }

    @isTest
    private static void nestedStepTest() {
        Map<String, Object> data = new Map<String, Object>{
            'count' => 0
        };
        Atom a = new Atom(data)
            .then(Atom.F.compute.apply('count', R.inc, 'count'))
            .then(new Atom.CompositeStep()
                .then(Atom.F.compute.apply('count', R.inc, 'count'))
                .then(Atom.F.compute.apply('count', R.inc, 'count'))
            )
            .fork();

        System.assertEquals(3, data.get('count'));
    }

    @isTest
    private static void forEachTest() {
        Map<String, Object> data = new Map<String, Object>{
            'count' => 0
        };
        Atom a = new Atom(data)
            .then(new Atom.ForEachStep('n', new List<Integer>{ 1, 2, 3 }, Atom.F.compute.applyN(new List<Object>{ 'count', R.add, 'count', 'n' })))
            .fork();

        System.assertEquals(6, data.get('count'));
    }

    @isTest
    private static void rangeTest() {
        Map<String, Object> data = new Map<String, Object>{
            'count' => 0
        };
        Atom a = new Atom(data)
            .then(new Atom.RangeStep('n', 1, 3, Atom.F.compute.applyN(new List<Object>{ 'count', R.add, 'count', 'n' })))
            .fork();

        System.assertEquals(6, data.get('count'));
    }

    @isTest
    private static void repeatTest() {
        Map<String, Object> data = new Map<String, Object>{
            'count' => 0
        };
        Atom a = new Atom(data)
            .then(new Atom.RepeatStep(3, Atom.F.compute.apply('count', R.inc, 'count')))
            .fork();

        System.assertEquals(3, data.get('count'));
    }

    @isTest
    private static void monitorTest() {
        Atom.registerMonitor(new TestMonitor());

        Atom a = new Atom()
            .then(Atom.F.compute.apply(R.debug.apply('running')))
            .then(Atom.F.compute.apply(R.debug.apply('running')))
            .fork();

        System.assertEquals(2, a.getState().getInterruptedTimes());
    }

    private class TestMonitor implements Atom.Monitor {

        public String getMessage() {
            return 'test monitor';
        }

        public Boolean isSafe(Atom.State s) {
            return false;
        }
    }
}
