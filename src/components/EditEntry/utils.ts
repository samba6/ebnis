import { EntryFragment } from "../../graphql/apollo-types/EntryFragment";
import { Dispatch } from "react";
import { ExperienceFragment_fieldDefs } from "../../graphql/apollo-types/ExperienceFragment";
import { UpdateEntryMutationFn } from "../../graphql/update-entry.mutation";

export interface Props {
  entry: EntryFragment;
  dispatch: Dispatch<EditEntryAction>;
  experienceTitle: string;
  fieldDefinitions: ExperienceFragment_fieldDefs[];
  onEdit: UpdateEntryMutationFn;
}

export enum EditEntryStateTag {
  initial = "initial",
  submitting = "submitting",
  formError = "form-error",
  serverFieldErrors = "server-field-errors",
  serverOtherErrors = "server-other-errors",
  aborted = "@components/edit-entry/aborted",
  completed = "@components/edit-entry/completed",
}

export type State =
  | [EditEntryStateTag.initial]
  | [EditEntryStateTag.submitting]
  | [EditEntryStateTag.serverOtherErrors, string];

export type EditEntryAction = [
  EditEntryStateTag.aborted | EditEntryStateTag.completed,
];
