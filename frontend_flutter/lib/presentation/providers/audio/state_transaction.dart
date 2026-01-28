class StateTransaction {
  final int version;
  final Map<String, dynamic> _changes = {};
  final DateTime timestamp;
  bool _isCommitted = false;
  bool _isRolledBack = false;
  final List<void Function()> _rollbackActions = [];

  StateTransaction({required this.version})
    : timestamp = DateTime.now();

  void setChange<T>(String key, T oldValue, T newValue, void Function() rollbackAction) {
    if (_isCommitted || _isRolledBack) {
      throw StateError('Transaction already finalized');
    }
    _changes[key] = {'old': oldValue, 'new': newValue};
    _rollbackActions.add(rollbackAction);
  }

  void commit() {
    if (_isRolledBack) {
      throw StateError('Cannot commit rolled back transaction');
    }
    _isCommitted = true;
  }

  void rollback() {
    if (_isCommitted) {
      throw StateError('Cannot rollback committed transaction');
    }
    _isRolledBack = true;
    for (final action in _rollbackActions.reversed) {
      action();
    }
  }

  bool get isCommitted => _isCommitted;
  bool get isRolledBack => _isRolledBack;
  bool get isActive => !_isCommitted && !_isRolledBack;
  Map<String, dynamic> get changes => Map.unmodifiable(_changes);
}

class StateVersionController {
  int _currentVersion = 0;
  StateTransaction? _activeTransaction;
  final List<StateTransaction> _history = [];
  static const int maxHistorySize = 10;

  int get currentVersion => _currentVersion;
  StateTransaction? get activeTransaction => _activeTransaction;

  StateTransaction beginTransaction() {
    if (_activeTransaction != null && _activeTransaction!.isActive) {
      _activeTransaction!.rollback();
    }
    
    _currentVersion++;
    _activeTransaction = StateTransaction(version: _currentVersion);
    return _activeTransaction!;
  }

  void commitTransaction() {
    if (_activeTransaction == null) {
      throw StateError('No active transaction');
    }
    
    _activeTransaction!.commit();
    _history.add(_activeTransaction!);
    
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
    
    _activeTransaction = null;
  }

  void rollbackTransaction() {
    if (_activeTransaction == null) {
      throw StateError('No active transaction');
    }
    
    _activeTransaction!.rollback();
    _currentVersion--;
    _activeTransaction = null;
  }

  bool isVersionValid(int version) {
    return version == _currentVersion;
  }

  void clearHistory() {
    _history.clear();
  }
}
