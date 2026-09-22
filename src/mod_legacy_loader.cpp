/*
 * mod-legacy loader.
 *
 * The playerbots fork auto-globs every module's sources into one lib and looks
 * up a loader symbol derived from the folder name: for folder "mod-legacy"
 * that symbol is exactly "Addmod_legacyScripts". It must exist and call our
 * real registration function.
 *
 * Released under GNU GPL v2 or (at your option) any later version.
 */

void AddLegacyScripts();

void Addmod_legacyScripts()
{
    AddLegacyScripts();
}
