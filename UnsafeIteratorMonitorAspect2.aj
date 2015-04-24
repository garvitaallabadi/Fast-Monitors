package mop;
import java.io.*;
import java.util.*;
import org.apache.commons.collections.map.*;
import java.lang.ref.WeakReference;



class UnsafeIteratorMonitor_1 implements Cloneable {
	public Object clone() {
		try {
			UnsafeIteratorMonitor_1 ret = (UnsafeIteratorMonitor_1) super.clone();
			return ret;
		}
		catch (CloneNotSupportedException e) {
			throw new InternalError(e.toString());
		}
	}
	int state;
	int event;

	//To check the number of monitors being created
	int name;

	boolean MOP_match = false;

	//Modified constructor
	public UnsafeIteratorMonitor_1 (int global) {
		state = 0;
		event = -1;
		name = global;

	}

	//States order: 0 2 1 3
	//Added transitions from state 1,3 to 2 on create
	synchronized public final void create(Collection c,Iterator i) {
		event = 1;
		switch(state) {
			case 0:
			switch(event) {
				case 1 : state = 2; break;
				default : state = -1; break;
			}
			break;
			case 1:
			switch(event) {
				case 3 : state = 3; break;
				case 2 : state = 1; break;
				case 1 : state = 2; break;
				default : state = -1; break;
			}
			break;
			case 2:
			switch(event) {
				case 3 : state = 2; break;
				case 2 : state = 1; break;
				case 1 : state = 2; break;
				default : state = -1; break;
			}
			break;
			case 3:
			switch(event) {
				case 1 : state = 2; break;
				default : state = -1; break;
			}
			break;
			default : state = -1;
		}

		MOP_match = state == 3;
	}

	//Added transition from state 3 to 1 on update
	synchronized public final void updatesource(Collection c) {
		event = 2;
		//System.out.println("update -> event: "+event);
		//System.out.println("update -> state: "+state);
		switch(state) {
			case 0:
			switch(event) {
				case 1 : state = 2; break;
				default : state = -1; break;
			}
			break;
			case 1:
			switch(event) {
				case 3 : state = 3; break;
				case 2 : state = 1; break;
				default : state = -1; break;
			}
			break;
			case 2:
			switch(event) {
				case 3 : state = 2; break;
				case 2 : state = 1; break;
				default : state = -1; break;
			}
			break;
			case 3:
			switch(event) {
				case 2 : state = 1; break;
				default : state = -1; break;
			}
			break;
			default : state = -1;
		}

		MOP_match = state == 3;
	}

	//Added transitions from state 3 to 2 on next
	synchronized public final void next(Iterator i) {
		event = 3;

		switch(state) {
			case 0:
			switch(event) {
				case 1 : state = 2; break;
				default : state = -1; break;
			}
			break;
			case 1:
			switch(event) {
				case 3 : state = 3; break;
				case 2 : state = 1; break;
				default : state = -1; break;
			}
			break;
			case 2:
			switch(event) {
				case 3 : state = 2; break;
				case 2 : state = 1; break;
				default : state = -1; break;
			}
			break;
			case 3:
			switch(event) {
				case 3 : state = 2; break;
				default : state = -1; break;
			}
			break;
			default : state = -1;
		}

		MOP_match = state == 3;
	}

	synchronized public final boolean MOP_match() {
		return MOP_match;
	}
	synchronized public final void reset() {
		state = 0;
		event = -1;

		MOP_match = false;
	}
}

public aspect UnsafeIteratorMonitorAspect2 {

	int glbl=0;

	static Map makeMap(Object key){
		if (key instanceof String) {
			return new HashMap();
		} else {
			return new ReferenceIdentityMap(AbstractReferenceMap.WEAK, AbstractReferenceMap.HARD, true);
		}
	}
	
	static List makeList(){
		return new ArrayList();
	}

	static Map indexing_lock = new HashMap();

	static Map UnsafeIterator_c_i_Map = null;
	static Map UnsafeIterator_c_Map = null;
	static Map UnsafeIterator_i_Map = null;

	//Instead of collection -> Iterator-Monitor Map in c-i map just kept collection->List of iterators in c_i Map
	//When create called check if Monitor for the collection is present in c_Map
	//If yes : Add the same monitor to i_map
	//Else create new monitor for collection Add to both c_map and i_map

	pointcut UnsafeIterator_create1(Collection c) : (call(Iterator Collection+.iterator()) && target(c)) && !within(UnsafeIteratorMonitor_1) && !within(UnsafeIteratorMonitorAspect2) && !adviceexecution();
	after (Collection c) returning (Iterator i) : UnsafeIterator_create1(c) {
		boolean skipAroundAdvice = false;
		Object obj = null;

		UnsafeIteratorMonitor_1 monitor = null;
		boolean toCreate = false;

		Map m = UnsafeIterator_c_i_Map;
		List l;
		if(m == null){
			synchronized(indexing_lock) {
				m = UnsafeIterator_c_i_Map;
				if(m == null) m = UnsafeIterator_c_i_Map = makeMap(c);
			}
		}

		synchronized(UnsafeIterator_c_i_Map) 
		{
			obj = m.get(c);
			
			if (obj == null) 
			{
				obj = makeList();
			}
			
			l = (List)obj;
	
			if(!l.contains(i))
			{
			l.add(i);
			}
			
			
		m = UnsafeIterator_c_Map;
		if (m == null) m = UnsafeIterator_c_Map = makeMap(c);

		synchronized(UnsafeIterator_c_Map) 
		{
			monitor = (UnsafeIteratorMonitor_1) m.get(c);
			if(monitor == null)
			{
				monitor = new UnsafeIteratorMonitor_1(++glbl);
			}
			m.put(c, monitor);
		}

		m = UnsafeIterator_i_Map;
		if (m == null) m = UnsafeIterator_i_Map = makeMap(i);
			
		synchronized(UnsafeIterator_i_Map) 
		{
			m.put(i, monitor);
		}

		

		{
			monitor.create(c,i);
			System.out.println("create -> name: "+monitor.name);
			if(monitor.MOP_match()) {
				System.out.println("improper iterator usage; name: "+monitor.name);
			}

		}
	}
	}

	pointcut UnsafeIterator_updatesource1(Collection c) : ((call(* Collection+.remove*(..)) || call(* Collection+.add*(..))) && target(c)) && !within(UnsafeIteratorMonitor_1) && !within(UnsafeIteratorMonitorAspect2) && !adviceexecution();
	after (Collection c) : UnsafeIterator_updatesource1(c) {
		boolean skipAroundAdvice = false;
		Object obj = null;

		Map m = UnsafeIterator_c_Map;
		if(m == null){
			synchronized(indexing_lock) {
				m = UnsafeIterator_c_Map;
				if(m == null) m = UnsafeIterator_c_Map = makeMap(c);
			}
		}

		synchronized(UnsafeIterator_c_Map) {
			obj = m.get(c);

		}
		if (obj != null) {
			synchronized(obj) {
					UnsafeIteratorMonitor_1 monitor = (UnsafeIteratorMonitor_1) obj;
					monitor.updatesource(c);
					System.out.println("update -> name: "+monitor.name);
					if(monitor.MOP_match()) {
						System.out.println("improper iterator usage");
					}

			}
		}

	}

	pointcut UnsafeIterator_next1(Iterator i) : (call(* Iterator.next()) && target(i)) && !within(UnsafeIteratorMonitor_1) && !within(UnsafeIteratorMonitorAspect2) && !adviceexecution();
	before (Iterator i) : UnsafeIterator_next1(i) {
		boolean skipAroundAdvice = false;
		Object obj = null;

		Map m = UnsafeIterator_i_Map;
		if(m == null){
			synchronized(indexing_lock) {
				m = UnsafeIterator_i_Map;
				if(m == null) m = UnsafeIterator_i_Map = makeMap(i);
			}
		}

		synchronized(UnsafeIterator_i_Map) {
			obj = m.get(i);

		}
		if (obj != null) {
			synchronized(obj) 
			{
				UnsafeIteratorMonitor_1 monitor = (UnsafeIteratorMonitor_1) obj;
				System.out.println("next -> name: "+monitor.name);
				monitor.next(i);
				if(monitor.MOP_match()) 
				{
					System.out.println("improper iterator usage");
				}	
			}
		}

	}

}

