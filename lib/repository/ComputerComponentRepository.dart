import '../models/ComputerComponent.dart';

class ComputerComponentRepository {
  final Map<int, ComputerComponent> components = {};
  int lastId = 1;

  bool add(ComputerComponent component) {
    if (component.id == -1) {
      component.id = lastId++;
    }

    if (components.containsKey(component.id)) {
      return false;
    }

    components[component.id] = component;
    return true;
  }

  bool remove(int id) {
    if (!components.containsKey(id)) {
      return false;
    }

    components.remove(id);
    return true;
  }

  bool update(ComputerComponent component) {
    if (!components.containsKey(component.id)) {
      return false;
    }

    components[component.id] = component;
    return true;
  }

  List<ComputerComponent> getAll() {
    return components.values.toList();
  }

  ComputerComponent? get(int id) {
    return components[id];
  }

  int size() {
    return components.length;
  }
}
