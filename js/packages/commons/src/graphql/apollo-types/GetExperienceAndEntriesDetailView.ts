/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { PaginationInput, DataTypes } from "./globalTypes";

// ====================================================
// GraphQL query operation: GetExperienceAndEntriesDetailView
// ====================================================

export interface GetExperienceAndEntriesDetailView_getExperience_dataDefinitions {
  __typename: "DataDefinition";
  id: string;
  /**
   * Name of field e.g start, end, meal
   */
  name: string;
  /**
   * The data type
   */
  type: DataTypes;
  /**
   * String that uniquely identifies this data definition has been
   * created offline. If an associated entry is also created
   * offline, then `dataDefinition.definitionId` **MUST BE** the same as this
   * field and will be validated as such.
   */
  clientId: string | null;
}

export interface GetExperienceAndEntriesDetailView_getExperience {
  __typename: "Experience";
  /**
   * The title of the experience
   */
  id: string;
  title: string;
  /**
   * The description of the experience
   */
  description: string | null;
  /**
   * The client ID. For experiences created on the client while server is
   * offline and to be saved , the client ID uniquely identifies such and can
   * be used to enforce uniqueness at the DB level. Not providing client_id
   * assumes a fresh experience.
   */
  clientId: string | null;
  insertedAt: any;
  updatedAt: any;
  /**
   * The field definitions used for the experience entries
   */
  dataDefinitions: GetExperienceAndEntriesDetailView_getExperience_dataDefinitions[];
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_pageInfo {
  __typename: "PageInfo";
  /**
   * When paginating forwards, are there more items?
   */
  hasNextPage: boolean;
  /**
   * When paginating backwards, are there more items?
   */
  hasPreviousPage: boolean;
  /**
   * When paginating backwards, the cursor to continue.
   */
  startCursor: string | null;
  /**
   * When paginating forwards, the cursor to continue.
   */
  endCursor: string | null;
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_edges_node_dataObjects {
  __typename: "DataObject";
  id: string;
  data: any;
  definitionId: string;
  /**
   * Client ID indicates that data object was created offline
   */
  clientId: string | null;
  insertedAt: any;
  updatedAt: any;
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_edges_node {
  __typename: "Entry";
  /**
   * Entry ID
   */
  id: string;
  /**
   * The ID of experience to which this entry belongs.
   */
  experienceId: string;
  /**
   * The client ID which indicates that an entry has been created while server
   * is offline and is to be saved. The client ID uniquely
   * identifies this entry and will be used to prevent conflict while saving entry
   * created offline and must thus be non null in this situation.
   */
  clientId: string | null;
  insertedAt: any;
  updatedAt: any;
  /**
   * The list of data belonging to this entry.
   */
  dataObjects: (GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_edges_node_dataObjects | null)[];
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_edges {
  __typename: "EntryEdge";
  cursor: string | null;
  node: GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_edges_node | null;
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries {
  __typename: "EntryConnection";
  pageInfo: GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_pageInfo;
  edges:
    | (GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries_edges | null)[]
    | null;
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess {
  __typename: "GetEntriesSuccess";
  entries: GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess_entries;
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesErrors_errors {
  __typename: "ExperienceError";
  experienceId: string;
  /**
   * This will mostly be experience not found error
   */
  error: string;
}

export interface GetExperienceAndEntriesDetailView_getEntries_GetEntriesErrors {
  __typename: "GetEntriesErrors";
  errors: GetExperienceAndEntriesDetailView_getEntries_GetEntriesErrors_errors;
}

export type GetExperienceAndEntriesDetailView_getEntries =
  | GetExperienceAndEntriesDetailView_getEntries_GetEntriesSuccess
  | GetExperienceAndEntriesDetailView_getEntries_GetEntriesErrors;

export interface GetExperienceAndEntriesDetailView {
  /**
   * Get an experience
   */
  getExperience: GetExperienceAndEntriesDetailView_getExperience | null;
  /**
   * Get entries belonging to an experience.
   * The entries returned may be paginated
   */
  getEntries: GetExperienceAndEntriesDetailView_getEntries | null;
}

export interface GetExperienceAndEntriesDetailViewVariables {
  experienceId: string;
  pagination: PaginationInput;
}
