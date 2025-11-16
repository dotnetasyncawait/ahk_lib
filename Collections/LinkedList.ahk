class LinkedList {
	/**
	 * @type {LinkedListNode}
	 */
	_head := ""
	
	/**
	 * @type {LinkedListNode}
	 */
	_tail := ""
	
	_size := 0
	
	__Enum(_) => LinkedList.Enumerator(this)
	
	First => this._head
	Last  => this._tail
	Size  => this._size
	
	AddLast(value) {
		node := value is LinkedListNode ? value : LinkedListNode(value)
		
		if this._size == 0 {
			this._head := this._tail := node
		} else {
			this._tail._next := node
			node._prev := this._tail
			this._tail := node
		}
		
		node._list := this
		this._size++
	}
	
	RemoveLast(&value) {
		if this._size == 0 {
			value := ""
			return false
		}
		
		node := this._tail
		
		if this._size == 1 {
			this._head := this._tail := ""
		} else {
			this._tail := node._prev
			this._tail._next := ""
		}
		
		value := node.Value
		
		node._Invalidate()
		this._size--
		
		return true
	}
	
	RemoveFirst(&value) {
		if this._size == 0 {
			value := ""
			return false
		}
		
		node := this._head
		
		if this._size == 1 {
			this._head := this._tail := ""
		} else {
			this._head := node._next
			this._head._prev := ""
		}
		
		value := node.Value
		
		node._Invalidate()
		this._size--
		
		return true
	}
	
	/**
	 * @param {LinkedListNode} node
	 */
	MoveToEnd(node) {
		if !(node is LinkedListNode) {
			throw TypeError(Format("Invalid type. Expected: 'LinkedListNode'; got: '{}'.", Type(node)))
		}
		
		if node.List != this {
			throw Error("Node does not belong to 'this' LinkedList.")
		}
		
		if this._size < 2 || node.Next == "" {
			return
		}
		
		if node._prev == "" {
			; The node is a head
			this._head := node._next
			this._head._prev := ""
		} else {
			; The node is in the middle
			node._prev._next := node._next
			node._next._prev := node._prev
		}
		
		; Move node to the end
		this._tail._next := node
		node._prev := this._tail
		this._tail := node
		node._next := ""
	}
	
	Clear() {
		if this._size == 0 {
			return
		}
		
		current := this._head
		while current != "" {
			next := current.Next
			current._Invalidate()
			current := next
		}
		
		this._head := this._tail := ""
		this._size := 0
	}
	
	class Enumerator {
		/**
		 * @type {LinkedList}
		 */
		_list := unset
		
		/**
		 * @type {LinkedListNode}
		 */
		_node := -1
		
		__New(list) => this._list := list
		
		Call(&value) {
			if this._node == -1 {
				; TODO: store version (once implement)
				this._node := this._list.First
			}
			
			if not current := this._node {
				value := ""
				return false
			}
			
			value := current.Value
			this._node := current.Next
			return true
		}
	}
}

class LinkedListNode {
	/**
	 * @type {LinkedListNode}
	 */
	_prev := ""
	
	/**
	 * @type {LinkedListNode}
	 */
	_next := ""
	
	/**
	 * @type {LinkedList}
	 */
	_list := ""
	
	Value := unset
	
	__New(value) {
		this.Value := value
	}
	
	Prev => this._prev
	Next => this._next
	List => this._list
	
	_Invalidate() {
		this._prev := this._next := this._list := ""
	}
}