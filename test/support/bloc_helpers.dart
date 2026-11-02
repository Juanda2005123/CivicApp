import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adds [event] and returns every state the bloc emits until it goes idle.
///
/// The blocs are tested without any widget: an event goes in, states come out.
Future<List<S>> emittedStates<E, S>(Bloc<E, S> bloc, E event) async {
  final states = <S>[];
  final subscription = bloc.stream.listen(states.add);
  bloc.add(event);
  await pumpEventQueue();
  await subscription.cancel();
  return states;
}
