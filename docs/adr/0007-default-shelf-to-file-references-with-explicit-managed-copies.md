# Default Shelf to File References with Explicit Managed Copies

File Shelf should store file references by default and use Temporary Copy or Pinned managed copies only when the user explicitly chooses that behavior or when the source is volatile. The UI must make storage mode visible enough that users understand whether Desktop Island owns a copy.

This avoids surprising disk usage and accidental file duplication while preserving the fast drag/drop UX. Managed copies remain available for workflows where the user wants Desktop Island to hold onto files beyond their original location.
