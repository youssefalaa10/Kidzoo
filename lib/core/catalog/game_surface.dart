/// Where a catalog entry is offered to the child.
///
/// This drives grid membership, so the Games and Education grids are a
/// *query over the catalog* rather than two hand-maintained lists. Adventure
/// Mode adds activities without touching either grid, which is the guarantee
/// that free play is never altered by story work.
enum GameSurface {
  games,
  education,
}
