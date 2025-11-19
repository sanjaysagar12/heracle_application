class ExerciseRepository {
  Future<List<Map<String, String>>> getExercises() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [
      {'id': 'w1','name': 'Bench Press (Barbell)','desc':'Chest','image':'https://images.unsplash.com/photo-1558611848-73f7eb4001d7?w=200','category':'Chest'},
      {'id': 'w2','name': 'Incline Dumbbell Press','desc':'Chest','image':'https://images.unsplash.com/photo-1554284126-0c3d1d1cc2a0?w=200','category':'Chest'},
      {'id': 'w3','name': 'Barbell Curl','desc':'Biceps','image':'https://images.unsplash.com/photo-1526403222633-3c9b7f3c6f6f?w=200','category':'Biceps'},
      {'id': 'w4','name': 'Tricep Dip','desc':'Triceps','image':'https://images.unsplash.com/photo-1517976487492-5750f3195933?w=200','category':'Triceps'},
      {'id': 'w5','name': 'Squat','desc':'Legs','image':'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=200','category':'Legs'},
      {'id': 'w6','name': 'Push Up','desc':'Functional','image':'https://images.unsplash.com/photo-1594737625785-0a6d7b5b6c1a?w=200','category':'Functional'},
      // add more as needed
    ];
  }
}
