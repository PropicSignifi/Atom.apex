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
/**
 * Atom tries to execute your code even when you may reach the governor limits
 *
 * Example:
 * public class CustomCompute extends Atom.Compute {
 *     public override void execute(Atom.State s) {
 *         Set<Id> ids = (Set<Id>)s.getData('ids');
 *         // Custom code
 *         s.setData('accs', accList);
 *     }
 * }
 *
 * new Atom(new Map<String, Object>{ 'ids' => new Set<Id>{  } })
 *     .then(new CustomCompute())
 *     .then(new Atom.ForEachStep('acc', 'accs', new CustomAccCompute()))
 *     .fork();
 *
 * Basically, you put your business logic in the compute and chain the computes together
 * into an Atom, which runs the computes one after another in a queueable job
 *
 * If at some point, Atom detects that certain governor limits may reach, it will automatically
 * start a new queueable job and then continue to execute the remaining computes
 *
 * Each switch to the new queueable job is called an interruption
 *
 * You can manually start a new queueable job by calling 'Atom.State.setInterrupted'
 * */
public class Atom implements Queueable, Database.AllowsCallouts {
    /**
     * Exported Funcs
     * */
    public static final Funcs F = new Funcs();

    // The global step
    private CompositeStep globalStep = null;

    // The global state
    private State globalState = null;

    // The max interruptions
    private Integer maxInterruptions = 10;

    /**
     * Create an Atom with the initial data
     *
     * Example:
     * Atom a = new Atom(new Map<String, Object>{  });
     *
     * @param initialData The initial data
     * */
    public Atom(Map<String, Object> initialData) {
        this.globalStep = new CompositeStep();
        this.globalState = new State(initialData);
    }

    /**
     * Create an Atom with empty data
     *
     * Example:
     * Atom a = new Atom();
     *
     * */
    public Atom() {
        this(null);
    }

    /**
     * Get the State object
     *
     * Example:
     * Atom.State state = a.getState();
     *
     * @return State
     * */
    public State getState() {
        return this.globalState;
    }

    /**
     * Get the max interruptions
     *
     * Example:
     * Integer max = a.getMaxInterruptions();
     *
     * @return Integer
     * */
    public Integer getMaxInterruptions() {
        return this.maxInterruptions;
    }

    /**
     * Set the max interruptions
     *
     * Example:
     * a.setMaxInterruptions(20);
     *
     * @param max The max interruptions
     * @return Atom
     * */
    public Atom setMaxInterruptions(Integer max) {
        this.maxInterruptions = max;

        return this;
    }

    /**
     * Chain a next step
     *
     * Example:
     * a.then(new Atom.CompositeStep());
     *
     * @param next The next step
     * @return Atom
     * */
    public Atom then(Step next) {
        this.globalStep.then(next);

        return this;
    }

    /**
     * Chain a next compute as the simple step
     *
     * Example:
     * a.then(new CustomCompute());
     *
     * @param c The next compute
     * @return Atom
     * */
    public Atom then(Compute c) {
        return this.then(new SimpleStep(c));
    }

    /**
     * Chain a next Func as the simple step
     *
     * Example:
     * a.then(R.debug.apply('test'));
     *
     * @param f The Func
     * @return Atom
     * */
    public Atom then(Func f) {
        return this.then(new FuncCompute(f));
    }

    /**
     * Trigger the Atom to run
     *
     * Example:
     * Atom a = new Atom()
     *     .then(new CustomCompute())
     *     .fork();
     *
     * @return Atom
     * */
    public Atom fork() {
        if(!Test.isRunningTest()) {
            System.enqueueJob(this);
        }
        else {
            this.execute(null);
        }

        return this;
    }

    /**
     * Callback method for queueable job
     *
     * @param context The queueable context
     * */
    public void execute(QueueableContext context) {
        this.globalState.setInterrupted(false);

        while(!this.globalStep.isFinished(this.globalState) && !this.globalState.isInterrupted()) {
            this.executeStep();
        }

        if(this.globalState.isInterrupted()) {
            if(this.globalState.getInterruptedTimes() > this.maxInterruptions) {
                throw new AtomException('Max interruption limit is reached');
            }

            this.fork();
        }
    }

    // Execute the step
    private void executeStep() {
        this.globalStep.execute(this.globalState);

        for(Monitor m : Atom.monitors) {
            if(!m.isSafe(this.globalState)) {
                String message = m.getMessage();
                System.debug(LoggingLevel.Warn, message);

                this.globalState.setInterrupted(true);
                return;
            }
        }
    }

    // The registered monitors
    private static final List<Monitor> monitors = new List<Monitor>();

    static {
        // Monitor aggregate queries
        registerMonitor(new AggregateQueriesMonitor());

        // Monitor callouts
        registerMonitor(new CalloutsMonitor());

        // Monitor cpu time
        registerMonitor(new CpuTimeMonitor());

        // Monitor DML rows
        registerMonitor(new DMLRowsMonitor());

        // Monitor DML statements
        registerMonitor(new DMLStatementsMonitor());

        // Monitor email invocations
        registerMonitor(new EmailInvocationsMonitor());

        // Monitor future calls
        registerMonitor(new FutureCallsMonitor());

        // Monitor heap size
        registerMonitor(new HeapSizeMonitor());

        // Monitor mobile push ape calls
        registerMonitor(new MobilePushApexCallsMonitor());

        // Monitor queries
        registerMonitor(new QueriesMonitor());

        // Monitor query locator rows
        registerMonitor(new QueryLocatorRowsMonitor());

        // Monitor query rows
        registerMonitor(new QueryRowsMonitor());

        // Monitor queueable jobs
        registerMonitor(new QueueableJobsMonitor());

        // Monitor sosl queries
        registerMonitor(new SoslQueriesMonitor());
    }

    /**
     * Register an Atom monitor
     *
     * Example:
     * Atom.registerMonitor(new CustomMonitor());
     *
     * @param m The Atom monitor
     * */
    public static void registerMonitor(Monitor m) {
        Atom.monitors.add(m);
    }

    /**
     * The state of the Atom
     *
     * Users should load and store data to the state
     * */
    public class State {
        // The map of data
        private Map<String, Object> data = null;

        // The interrupted flag
        private Boolean interrupted = false;

        // How many times interrupted
        private Integer interruptedTimes = 0;

        /**
         * Create a state from the map
         *
         * @param data The data map
         * */
        State(Map<String, Object> data) {
            this.data = data;
            if(this.data == null) {
                this.data = new Map<String, Object>();
            }
        }

        /**
         * Create an empty state
         *
         * */
        State() {
            this(null);
        }

        /**
         * Get all the data from the state
         *
         * Example:
         * Map<String, Object> data = s.all();
         *
         * @return Map<String, Object>
         * */
        public Map<String, Object> all() {
            return this.data;
        }

        /**
         * Get the data by the key
         *
         * Example:
         * String name = (String)s.getData('name');
         *
         * @param key The key of the data
         * @return Object
         * */
        public Object getData(String key) {
            return this.data.get(key);
        }

        /**
         * Set the data by the key
         *
         * Example:
         * s.setData('name', 'value');
         *
         * @param key The key
         * @param value The value
         * */
        public void setData(String key, Object value) {
            this.data.put(key, value);
        }

        /**
         * Check if it is interrupted
         *
         * Example:
         * Boolean interrupted = s.isInterrupted();
         *
         * @return Boolean
         * */
        public Boolean isInterrupted() {
            return this.interrupted;
        }

        /**
         * Set the interrupted flag
         *
         * Example:
         * s.setInterrupted(true);
         *
         * @param interrupted The interrupted status
         * */
        public void setInterrupted(Boolean interrupted) {
            this.interrupted = interrupted;

            if(this.interrupted) {
                this.interruptedTimes += 1;
            }
        }

        /**
         * Get how many times it has been interrupted
         *
         * Example:
         * Integer count = s.getInterruptedTimes();
         *
         * @return Integer
         * */
        public Integer getInterruptedTimes() {
            return this.interruptedTimes;
        }
    }

    /**
     * The base class that represents your business logic
     *
     * Extend this class to provide your custom implementation
     *
     * Get/set data with state and if necessary, you can set the interrupted flag to switch
     * to a new queueable job
     *
     * Example:
     * public class CustomCompute extends Atom.Compute {
     *     public override void execute(Atom.State s) {
     *         String name = (String)s.getData('name');
     *         // Custom code
     *         s.setData('name', 'value');
     *     }
     * }
     * */
    public virtual class Compute {
        public virtual void execute(State state) {
        }
    }

    /**
     * The compute that wraps a Func
     *
     * Example:
     * new Atom()
     *     .then(new Atom.FuncCompute(R.debug.apply('test')))
     *     .fork();
     *
     * Basically, the Func receives the state map and is expected to return a new map of result
     * If Boolean true is returned, the state interrupted flag will be set
     * */
    public class FuncCompute extends Compute {
        // The Func
        private Func f;

        /**
         * Wrap the Func to a Compute
         *
         * Example:
         * new Atom()
         *     .then(new Atom.FuncCompute(R.debug.apply('test')))
         *     .fork();
         *
         * @param f The Func
         * */
        public FuncCompute(Func f) {
            this.f = f;
        }

        // Execute the compute
        public override void execute(State s) {
            if(this.f != null) {
                Map<String, Object> data = s.all();

                Object result = this.f.run(data);

                if(result == true) {
                    s.setInterrupted(true);
                }
                else if(result instanceof Map<String, Object>) {
                    Map<String, Object> newData = (Map<String, Object>)result;
                    for(String key : newData.keySet()) {
                        Object value = newData.get(key);
                        s.setData(key, value);
                    }
                }
            }
        }
    }

    /**
     * Used to monitor governor limits and other resource usage
     *
     * Example:
     * public class CustomMonitor implements Atom.Monitor {
     *     public String getMessage() {
     *         return 'Value limit is reached';
     *     }
     *
     *     public Boolean isSafe(Atom.State s) {
     *         Integer val = (Integer)s.getData('value');
     *         return val > 0;
     *     }
     * }
     * */
    public interface Monitor {
        /**
         * Return the message when it is not safe
         *
         * @return String
         * */
        String getMessage();

        /**
         * Check if the current state is safe
         *
         * @param s The state
         * @return Boolean
         * */
        Boolean isSafe(State s);
    }

    /**
     * The default monitor
     *
     * Extend this to provide basic custom implementations
     *
     * Example:
     * public class CustomMonitor extends Atom.DefaultMonitor {
     *     public CustomMonitor() {
     *         super('Value limit is reached');
     *     }
     *
     *     public override Integer getCurrentValue(Atom.State s) {
     *         return (Integer)s.getData('value');
     *     }
     *
     *     public override Integer getMaxValue(Atom.State s) {
     *         return 100;
     *     }
     * }
     * */
    public virtual class DefaultMonitor implements Monitor {
        // The monitor message
        private String message;

        /**
         * Set the message in the constructor
         * */
        public DefaultMonitor(String message) {
            this.message = message;
        }

        /**
         * Get the message
         *
         * @return String
         * */
        public String getMessage() {
            return this.message;
        }

        // Check if it is safe
        public Boolean isSafe(State s) {
            Integer current = this.getCurrentValue(s);
            Integer max = this.getMaxValue(s);

            return current <= max * 0.9;
        }

        /**
         * Extend this to provide your current value
         *
         * @param s The state
         * @return Integer
         * */
        public virtual Integer getCurrentValue(State s) {
            return 0;
        }

        /**
         * Extend this to provide your max value
         *
         * @param s The state
         * @return Integer
         * */
        public virtual Integer getMaxValue(State s) {
            return 0;
        }
    }

    public class AggregateQueriesMonitor extends DefaultMonitor {
        public AggregateQueriesMonitor() {
            super('Aggregate queries limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getAggregateQueries();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitAggregateQueries();
        }
    }

    public class CalloutsMonitor extends DefaultMonitor {
        public CalloutsMonitor() {
            super('Callout limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getCallouts();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitCallouts();
        }
    }

    public class CpuTimeMonitor extends DefaultMonitor {
        public CpuTimeMonitor() {
            super('Cpu time limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getCpuTime();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitCpuTime();
        }
    }

    public class DMLRowsMonitor extends DefaultMonitor {
        public DMLRowsMonitor() {
            super('DML row limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getDMLRows();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitDMLRows();
        }
    }

    public class DMLStatementsMonitor extends DefaultMonitor {
        public DMLStatementsMonitor() {
            super('DML statement limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getDMLStatements();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitDMLStatements();
        }
    }

    public class EmailInvocationsMonitor extends DefaultMonitor {
        public EmailInvocationsMonitor() {
            super('Email invocation limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getEmailInvocations();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitEmailInvocations();
        }
    }

    public class FutureCallsMonitor extends DefaultMonitor {
        public FutureCallsMonitor() {
            super('Future call limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getFutureCalls();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitFutureCalls();
        }
    }

    public class HeapSizeMonitor extends DefaultMonitor {
        public HeapSizeMonitor() {
            super('Heap size limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getHeapSize();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitHeapSize();
        }
    }

    public class MobilePushApexCallsMonitor extends DefaultMonitor {
        public MobilePushApexCallsMonitor() {
            super('Mobile push apex call limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getMobilePushApexCalls();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitMobilePushApexCalls();
        }
    }

    public class QueriesMonitor extends DefaultMonitor {
        public QueriesMonitor() {
            super('Query limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getQueries();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitQueries();
        }
    }

    public class QueryLocatorRowsMonitor extends DefaultMonitor {
        public QueryLocatorRowsMonitor() {
            super('Query locator row limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getQueryLocatorRows();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitQueryLocatorRows();
        }
    }

    public class QueryRowsMonitor extends DefaultMonitor {
        public QueryRowsMonitor() {
            super('Query row limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getQueryRows();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitQueryRows();
        }
    }

    public class QueueableJobsMonitor extends DefaultMonitor {
        public QueueableJobsMonitor() {
            super('Queueable job limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getQueueableJobs();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitQueueableJobs();
        }
    }

    public class SoslQueriesMonitor extends DefaultMonitor {
        public SoslQueriesMonitor() {
            super('Sosl query limit is reached');
        }

        public override Integer getCurrentValue(State s) {
            return Limits.getSoslQueries();
        }

        public override Integer getMaxValue(State s) {
            return Limits.getLimitSoslQueries();
        }
    }

    /**
     * A single step in the Atom
     *
     * Example:
     * new Atom()
     *     .then(new CustomStep())
     *
     * */
    public interface Step {
        /**
         * Check if this step is finished
         *
         * @param s The state
         * @return Boolean
         * */
        Boolean isFinished(State s);

        /**
         * Execute the step
         *
         * @param s The state
         * */
        void execute(State s);
    }

    /**
     * A simple step executes one compute
     * */
    public class SimpleStep implements Step {
        private Compute work;
        private Boolean finished = false;

        public SimpleStep(Compute work) {
            this.work = work;
        }

        public Boolean isFinished(State s) {
            return this.finished;
        }

        public void execute(State state) {
            this.work.execute(state);
            this.finished = true;
        }
    }

    /**
     * A composite step can contain multiple steps
     * */
    public class CompositeStep implements Step {
        private List<Step> steps = new List<Step>();

        public CompositeStep() {
        }

        public CompositeStep then(Step step) {
            this.steps.add(step);

            return this;
        }

        public CompositeStep then(Compute c) {
            return this.then(new SimpleStep(c));
        }

        public CompositeStep then(Func f) {
            return this.then(new FuncCompute(f));
        }

        public Boolean isFinished(State state) {
            for(Step s : this.steps) {
                if(!s.isFinished(state)) {
                    return false;
                }
            }

            return true;
        }

        public void execute(State state) {
            for(Step s : this.steps) {
                if(!s.isFinished(state)) {
                    s.execute(state);
                    return;
                }
            }
        }
    }

    /**
     * A ForEachStep execute the enclosing step in a for-each loop
     * */
    public class ForEachStep implements Step {
        private String itemKey;
        private String valuesKey;
        private List<Object> values;
        private Step body;

        private Integer index = 0;

        public ForEachStep(String itemKey, String valuesKey, List<Object> values, Step body) {
            this.itemKey = itemKey;
            this.valuesKey = valuesKey;
            this.values = values;
            this.body = body;
        }

        public ForEachStep(String itemKey, String valuesKey, Step body) {
            this(itemKey, valuesKey, null, body);
        }

        public ForEachStep(String itemKey, List<Object> values, Step body) {
            this(itemKey, null, values, body);
        }

        public ForEachStep(String itemKey, String valuesKey, Compute c) {
            this(itemKey, valuesKey, new SimpleStep(c));
        }

        public ForEachStep(String itemKey, List<Object> values, Compute c) {
            this(itemKey, values, new SimpleStep(c));
        }

        public ForEachStep(String itemKey, String valuesKey, Func f) {
            this(itemKey, valuesKey, new FuncCompute(f));
        }

        public ForEachStep(String itemKey, List<Object> values, Func f) {
            this(itemKey, values, new FuncCompute(f));
        }

        public Boolean isFinished(State s) {
            List<Object> values = this.getValues(s);
            return this.index >= values.size();
        }

        public void execute(State s) {
            if(this.body != null) {
                if(this.itemKey != null) {
                    List<Object> values = this.getValues(s);
                    Object item = values.get(this.index);
                    s.setData(this.itemKey, item);
                }

                this.body.execute(s);
            }

            this.index += 1;
        }

        private List<Object> getValues(State s) {
            List<Object> values = this.values;

            if(values == null) {
                values = (List<Object>)s.getData(this.valuesKey);
            }

            if(values == null) {
                values = new List<Object>();
            }

            return values;
        }
    }

    /**
     * A RangeStep executes the enclosing step with a provided range
     * */
    public class RangeStep implements Step {
        private ForEachStep delegator;

        public RangeStep(String itemKey, Integer min, Integer max, Step next) {
            List<Integer> numbers = new List<Integer>();
            for(Integer i = min; i <= max; i++) {
                numbers.add(i);
            }

            this.delegator = new ForEachStep(itemKey, numbers, next);
        }

        public RangeStep(String itemKey, Integer min, Integer max, Compute c) {
            this(itemKey, min, max, new SimpleStep(c));
        }

        public RangeStep(String itemKey, Integer min, Integer max, Func f) {
            this(itemKey, min, max, new FuncCompute(f));
        }

        public Boolean isFinished(State s) {
            return this.delegator.isFinished(s);
        }

        public void execute(State s) {
            this.delegator.execute(s);
        }
    }

    /**
     * A RepeatStep repeats the enclosing step
     * */
    public class RepeatStep implements Step {
        private RangeStep delegator;

        public RepeatStep(String itemKey, Integer count, Step next) {
            this.delegator = new RangeStep(itemKey, 0, count - 1, next);
        }

        public RepeatStep(String itemKey, Integer count, Compute c) {
            this(itemKey, count, new SimpleStep(c));
        }

        public RepeatStep(String itemKey, Integer count, Func f) {
            this(itemKey, count, new FuncCompute(f));
        }

        public RepeatStep(Integer count, Step next) {
            this(null, count, next);
        }

        public RepeatStep(Integer count, Compute c) {
            this(null, count, c);
        }

        public RepeatStep(Integer count, Func f) {
            this(null, count, f);
        }

        public Boolean isFinished(State s) {
            return this.delegator.isFinished(s);
        }

        public void execute(State s) {
            this.delegator.execute(s);
        }
    }

    // Exposed Funcs
    public class Funcs {
        public Func compute = new ComputeFunc();
    }

    private class ComputeFunc extends Func {
        public ComputeFunc() {
            super(-1);
        }

        public override Object execN(List<Object> args) {
            Map<String, Object> result = new Map<String, Object>();
            String targetKey = null;
            Integer index = 0;

            if(args[0] instanceof String) {
                targetKey = (String)args[0];
                index = 1;
            }

            Func f = (Func)args.get(index);
            List<Object> fArgs = new List<Object>();
            Map<String, Object> state = (Map<String, Object>)args.get(args.size() - 1);
            for(Integer i = index + 1; i < args.size() - 1; i++) {
                String key = (String)args.get(i);
                Object arg = state.get(key);
                fArgs.add(arg);
            }

            Object value = f.runN(fArgs);
            if(targetKey != null) {
                result.put(targetKey, value);
                return result;
            }
            else {
                return value;
            }
        }
    }

    public class AtomException extends Exception {
    }
}
