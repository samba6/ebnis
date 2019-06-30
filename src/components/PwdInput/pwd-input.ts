import { Dispatch } from "react";
import { FieldProps } from "formik";

export interface Props<TFormValues> extends FieldProps<TFormValues> {
  pwdType?: PasswordInputPayload;
  dispatch: Dispatch<PasswordInputAction>;
}

type TPasswordInputType = "@pwd-input/SET_PWD_TYPE";

export const PasswordInputType: TPasswordInputType = "@pwd-input/SET_PWD_TYPE";

export type PasswordInputPayload = "password" | "text";

export type PasswordInputAction = [TPasswordInputType, PasswordInputPayload];
