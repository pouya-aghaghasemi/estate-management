import 'package:estate_management/models/customers_model.dart';
import 'package:idb_shim/idb_browser.dart';
import '../models/property_model.dart';

class PropertyStorage {
  PropertyStorage._();

  static final PropertyStorage instance = PropertyStorage._();

  static const String _databaseName = 'estate_management_db';
  static const String _storeName = 'properties';
  static const String _customerStoreName = 'customers';
  static const int _databaseVersion = 2;
  Future<Database>? _databaseFuture;

  Future<Database> get _database {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final factory = getIdbFactory();

    if (factory == null) {
      throw UnsupportedError('مرورگر از IndexedDB پشتیبانی نمی‌کند.');
    }

    return factory.open(
      _databaseName,
      version: _databaseVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;

        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName, keyPath: 'id');
        }

        if (!db.objectStoreNames.contains(_customerStoreName)) {
          db.createObjectStore(_customerStoreName, keyPath: 'id');
        }
      },
    );
  }

  Future<void> saveProperty(PropertyModel property) async {
    final db = await _database;
    final transaction = db.transaction(_storeName, idbModeReadWrite);

    await transaction.objectStore(_storeName).put(property.toMap());
    await transaction.completed;
  }

  Future<List<PropertyModel>> getAllProperties() async {
    final db = await _database;
    final transaction = db.transaction(_storeName, idbModeReadOnly);

    final records = await transaction.objectStore(_storeName).getAll();
    await transaction.completed;

    return records.map((record) {
      return PropertyModel.fromMap(Map<String, dynamic>.from(record as Map));
    }).toList();
  }

  Future<PropertyModel?> getPropertyById(String id) async {
    final db = await _database;
    final transaction = db.transaction(_storeName, idbModeReadOnly);

    final record = await transaction.objectStore(_storeName).getObject(id);

    await transaction.completed;

    if (record == null) return null;

    return PropertyModel.fromMap(Map<String, dynamic>.from(record as Map));
  }

  Future<void> deleteProperty(String id) async {
    final db = await _database;
    final transaction = db.transaction(_storeName, idbModeReadWrite);

    await transaction.objectStore(_storeName).delete(id);
    await transaction.completed;
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final db = await _database;
    final transaction = db.transaction(_customerStoreName, idbModeReadWrite);

    await transaction.objectStore(_customerStoreName).put(customer.toMap());

    await transaction.completed;
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await _database;
    final transaction = db.transaction(_customerStoreName, idbModeReadOnly);

    final records = await transaction.objectStore(_customerStoreName).getAll();

    await transaction.completed;

    return records.map((record) {
      return CustomerModel.fromMap(Map<String, dynamic>.from(record as Map));
    }).toList();
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await _database;
    final transaction = db.transaction(_customerStoreName, idbModeReadOnly);

    final record = await transaction
        .objectStore(_customerStoreName)
        .getObject(id);

    await transaction.completed;

    if (record == null) return null;

    return CustomerModel.fromMap(Map<String, dynamic>.from(record as Map));
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _database;
    final transaction = db.transaction(_customerStoreName, idbModeReadWrite);

    await transaction.objectStore(_customerStoreName).delete(id);

    await transaction.completed;
  }
}
