import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/generate_recipe.dart';

import 'package:injectable/injectable.dart';

abstract class AiRecipeState extends Equatable {
  const AiRecipeState();

  @override
  List<Object?> get props => [];
}

class AiRecipeInitial extends AiRecipeState {}

class AiRecipeImageAnalyzing extends AiRecipeState {}

class AiRecipeGenerating extends AiRecipeState {}

class AiRecipeSuccess extends AiRecipeState {
  final Recipe recipe;
  const AiRecipeSuccess(this.recipe);

  @override
  List<Object?> get props => [recipe];
}

class AiRecipeFailure extends AiRecipeState {
  final String message;
  const AiRecipeFailure(this.message);

  @override
  List<Object?> get props => [message];
}

@injectable
class AiRecipeCubit extends Cubit<AiRecipeState> {
  final GenerateRecipe generateRecipe;

  AiRecipeCubit(this.generateRecipe) : super(AiRecipeInitial());

  Future<void> generateFromIngredients(List<String> ingredients, UserProfileEntity profile) async {
    emit(AiRecipeGenerating());
    try {
      final recipe = await generateRecipe.fromIngredients(ingredients, profile);
      emit(AiRecipeSuccess(recipe));
    } catch (e) {
      emit(AiRecipeFailure(e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '')));
    }
  }

  Future<void> generateFromImage(String imageBase64, UserProfileEntity profile) async {
    emit(AiRecipeImageAnalyzing());
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulating camera scanning phase
    emit(AiRecipeGenerating());
    try {
      final recipe = await generateRecipe.fromImage(imageBase64, profile);
      emit(AiRecipeSuccess(recipe));
    } catch (e) {
      emit(AiRecipeFailure(e.toString().replaceAll('Exception: ', '').replaceAll('ServerException: ', '')));
    }
  }

  void reset() {
    emit(AiRecipeInitial());
  }
}
