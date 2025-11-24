/// Simple abstraction implemented by data models that can serialize to/from JSON.
typedef JsonMap = Map<String, dynamic>;

abstract class BaseModel {
  const BaseModel();

  JsonMap toJson();
}

abstract class JsonModel<T extends BaseModel> extends BaseModel {
  const JsonModel();

  T copyWith();

  static R fromJson<R>(JsonMap json, R Function(JsonMap json) factory) {
    return factory(json);
  }
}
