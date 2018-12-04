

/* tslint:disable */
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: ExperienceMutation
// ====================================================

export interface ExperienceMutation_experience {
  id: string;
}

export interface ExperienceMutation {
  experience: ExperienceMutation_experience | null;
}

export interface ExperienceMutationVariables {
  experience: CreateExperience;
}


/* tslint:disable */
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: GetAnExperience
// ====================================================

export interface GetAnExperience_experience_fields {
  id: string;
  name: string;                   // Name of field e.g start, end, meal
  singleLineText: string | null;  // A single line text field
  multiLineText: string | null;   // A multi line text field
  integer: number | null;         // An integer field type
  decimal: number | null;         // A floating point number field type
  date: any | null;               // Date field type
  datetime: any | null;           // Datetime field type
  type: string;                   // The data type of the field
}

export interface GetAnExperience_experience {
  id: string;
  title: string;
  description: string | null;
  fields: (GetAnExperience_experience_fields | null)[];
}

export interface GetAnExperience {
  experience: GetAnExperience_experience | null;  // get an experience
}

export interface GetAnExperienceVariables {
  experience: GetExperience;
}


/* tslint:disable */
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: LoginMutation
// ====================================================

export interface LoginMutation_login {
  id: string;
  name: string;
  email: string;
  jwt: string;
}

export interface LoginMutation {
  login: LoginMutation_login | null;
}

export interface LoginMutationVariables {
  login: LoginUser;
}


/* tslint:disable */
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: UserRegMutation
// ====================================================

export interface UserRegMutation_registration {
  id: string;
  name: string;
  email: string;
  jwt: string;
}

export interface UserRegMutation {
  registration: UserRegMutation_registration | null;
}

export interface UserRegMutationVariables {
  registration: Registration;
}


/* tslint:disable */
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL fragment: ExpFieldFragment
// ====================================================

export interface ExpFieldFragment {
  id: string;
  name: string;                   // Name of field e.g start, end, meal
  singleLineText: string | null;  // A single line text field
  multiLineText: string | null;   // A multi line text field
  integer: number | null;         // An integer field type
  decimal: number | null;         // A floating point number field type
  date: any | null;               // Date field type
  datetime: any | null;           // Datetime field type
  type: string;                   // The data type of the field
}


/* tslint:disable */
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL fragment: ExperienceFragment
// ====================================================

export interface ExperienceFragment {
  id: string;
  title: string;
  description: string | null;
}


/* tslint:disable */
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL fragment: UserFragment
// ====================================================

export interface UserFragment {
  id: string;
  name: string;
  email: string;
  jwt: string;
}

/* tslint:disable */
// This file was automatically generated and should not be edited.

//==============================================================
// START Enums and Input Objects
//==============================================================

export enum FieldType {
  DATE = "DATE",
  DATETIME = "DATETIME",
  DECIMAL = "DECIMAL",
  INTEGER = "INTEGER",
  MULTI_LINE_TEXT = "MULTI_LINE_TEXT",
  SINGLE_LINE_TEXT = "SINGLE_LINE_TEXT",
}

// Variables for creating Experience
export interface CreateExperience {
  description?: string | null;
  fields: (CreateExpField | null)[];
  title: string;
}

// Variables for creating field for an existing experience
export interface CreateExpField {
  name: string;
  type: FieldType;
  value?: string | null;
}

// Variables for getting an experience
export interface GetExperience {
  id: string;
}

// Variables for login in User
export interface LoginUser {
  email: string;
  password: string;
}

// Variables for creating User and credential
export interface Registration {
  email: string;
  name: string;
  password: string;
  passwordConfirmation: string;
  source: string;
}

//==============================================================
// END Enums and Input Objects
//==============================================================