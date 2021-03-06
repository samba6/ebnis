defmodule EbnisData.Schema.ExperienceTest do
  use EbnisData.DataCase, async: true

  import ExUnit.CaptureLog

  alias EbnisData.Schema
  alias EbnisData.Factory.Registration, as: RegFactory
  alias EbnisData.Factory.Experience, as: Factory
  alias EbnisData.Factory.DataDefinition, as: DataDefinitionFactory
  alias EbnisData.Query.Experience, as: Query
  alias EbnisData.Factory.Entry, as: EntryFactory

  @moduletag capture_log: true
  @bogus_id Ecto.ULID.generate()
  @inserted_at_string "2016-05-05T09:41:22Z"

  describe "erstellen erfahrungen" do
    # @tag :skip
    test "unauthorized" do
      variables = %{
        "input" =>
          Factory.params()
          |> Factory.stringify()
      }

      assert {:ok,
              %{
                errors: [
                  %{
                    message: error
                  }
                ]
              }} =
               Absinthe.run(
                 Query.create_experiences(),
                 Schema,
                 variables: variables
               )

      assert is_binary(error)
    end

    test "fails: insensitive title not unique" do
      user = RegFactory.insert()
      # title lower
      Factory.insert(title: "a1", user_id: user.id)

      title_case_insensitive_not_unique_input = %{
        # title upper
        "title" => "A1",
        "dataDefinitions" => [
          %{
            "name" => "a1",
            "type" => "DATE"
          }
        ]
      }

      variables = %{
        "input" => [
          title_case_insensitive_not_unique_input
        ]
      }

      assert {:ok,
              %{
                data: %{
                  "createExperiences" => [
                    %{
                      "errors" => %{
                        "meta" => %{
                          "index" => 0,
                          "clientId" => nil
                        },
                        "title" => title_case_insensitive_not_unique_error
                      }
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.create_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(title_case_insensitive_not_unique_error)
    end

    test "fails: definition name taken - case insensitive" do
      user = RegFactory.insert()

      definition_name_taken_input =
        %{
          data_definitions: [
            DataDefinitionFactory.params(name: "F0"),
            DataDefinitionFactory.params(name: "f0")
          ],
          client_id: "a"
        }
        |> Factory.params()
        |> Factory.stringify()

      variables = %{
        "input" => [
          definition_name_taken_input
        ]
      }

      assert {:ok,
              %{
                data: %{
                  "createExperiences" => [
                    %{
                      "errors" => %{
                        "meta" => %{
                          "index" => 0,
                          "clientId" => "a"
                        },
                        "title" => nil,
                        "dataDefinitions" => [
                          %{
                            "index" => 1,
                            "name" => definition_name_taken_error,
                            "type" => nil
                          }
                        ]
                      }
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.create_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(definition_name_taken_error)
    end

    # @tag :skip
    test "fails: data definition type does not exist" do
      user = RegFactory.insert()

      attrs = %{
        data_definitions: [
          %{
            name: "ff",
            type: "integer1"
          }
        ],
        user_id: user.id,
        title: "aa"
      }

      assert {
               :error,
               %{
                 changes: %{
                   data_definitions: [
                     %{
                       errors: [
                         type: {
                           type_error,
                           _
                         }
                       ]
                     }
                   ]
                 }
               }
             } = EbnisData.create_experience(attrs)

      assert is_binary(type_error)
    end

    test "fails: client_id taken" do
      user = RegFactory.insert()
      inserted_at_string = @inserted_at_string
      client_id_taken = ".,"

      success_no_entry_input = %{
        "title" => "a1",
        "dataDefinitions" => [
          %{
            "name" => "a1",
            "type" => "DATE"
          }
        ],
        "insertedAt" => inserted_at_string,
        "updatedAt" => inserted_at_string,
        "clientId" => client_id_taken
      }

      client_id_taken_input = %{
        "clientId" => client_id_taken,
        "title" => "a3",
        "dataDefinitions" => [
          %{
            "name" => "a1",
            "type" => "DATE"
          }
        ]
      }

      variables = %{
        "input" => [
          success_no_entry_input,
          client_id_taken_input
        ]
      }

      assert {:ok,
              %{
                data: %{
                  "createExperiences" => [
                    %{
                      "experience" => %{
                        "insertedAt" => ^inserted_at_string,
                        "updatedAt" => ^inserted_at_string,
                        "id" => _,
                        "title" => "a1",
                        "dataDefinitions" => [
                          %{
                            "name" => "a1"
                          }
                        ],
                        "clientId" => ^client_id_taken
                      }
                    },
                    %{
                      "errors" => %{
                        "meta" => %{
                          "index" => 1,
                          "clientId" => ^client_id_taken
                        },
                        "clientId" => client_id_taken_error,
                        "title" => nil
                      }
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.create_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(client_id_taken_error)
    end

    # @tag :skip
    test "offline success with entries" do
      user = RegFactory.insert()

      input = %{
        "title" => "a7",
        "clientId" => "a7",
        "dataDefinitions" => [
          %{
            "name" => "a1",
            "clientId" => "a1",
            "type" => "INTEGER"
          }
        ],
        "entries" => [
          %{
            "experienceId" => "a7",
            "dataObjects" => [
              %{
                "definitionId" => "a1",
                "data" => ~s({"integer":1})
              }
            ]
          }
        ]
      }

      variables = %{
        "input" => [
          input
        ]
      }

      assert {:ok,
              %{
                data: %{
                  "createExperiences" => [
                    %{
                      "entries" => [
                        %{
                          "entry" => %{
                            "experienceId" => experience_id,
                            "dataObjects" => [
                              %{
                                "definitionId" => definition_id
                              }
                            ]
                          }
                        }
                      ],
                      "experience" => %{
                        "id" => experience_id,
                        "title" => "a7",
                        "clientId" => "a7",
                        "dataDefinitions" => [
                          %{
                            "name" => "a1",
                            "id" => definition_id
                          }
                        ]
                      }
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.create_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )
    end

    # @tag :skip
    test "success: create with comments" do
      user = RegFactory.insert()

      input = %{
        "clientId" => "a4",
        "title" => "a4",
        "dataDefinitions" => [
          %{
            "name" => "a1",
            "type" => "INTEGER"
          }
        ],
        "comment_text" => "text"
      }

      variables = %{
        "input" => [
          input
        ]
      }

      assert {:ok,
              %{
                data: %{
                  "createExperiences" => [
                    %{
                      "experience" => %{
                        "id" => _,
                        "title" => "a4",
                        "dataDefinitions" => [
                          %{
                            "name" => "a1"
                          }
                        ],
                        "clientId" => "a4",
                        "comments" => [
                          %{
                            "id" => _,
                            "text" => "text"
                          }
                        ]
                      }
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.create_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )
    end
  end

  describe "update experiences" do
    test "unauthorized" do
      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "error" => error
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: %{
                   "input" => []
                 }
               )

      assert is_binary(error)
    end

    test "scheitern: erfahrung nicht gefunden" do
      bogus_id = @bogus_id
      user = RegFactory.insert()

      experience_not_found_variable = %{
        "experienceId" => bogus_id
      }

      variables = %{
        "input" => [
          experience_not_found_variable
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "errors" => %{
                           "experienceId" => ^bogus_id,
                           "error" => experience_not_found_error
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(experience_not_found_error)
    end

    test "erfahrfung erhebt Ausnahme" do
      user = RegFactory.insert()
      raises_id = "1"

      raises_variable = %{
        "experienceId" => raises_id
      }

      variables = %{
        "input" => [
          raises_variable
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "errors" => %{
                           "experienceId" => ^raises_id,
                           "error" => raises_error
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(raises_error)
    end

    test "scheitern: eigene Felder fehler: Erfahrungs Titel zu klein" do
      user = RegFactory.insert()

      %{
        id: experience_id
      } =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      own_fields_error_variable = %{
        "experienceId" => experience_id,
        "ownFields" => %{
          # title must be at least 2 chars long
          "title" => "a"
        }
      }

      variables = %{
        "input" => [
          own_fields_error_variable
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "ownFields" => %{
                             "errors" => %{
                               "title" => title_error
                             }
                           }
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(title_error)
    end

    test "erfolg: Erfahrungs Titel bearbeiten" do
      user = RegFactory.insert()

      %{
        id: experience,
        title: own_fields_success_title
      } =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      updated_title = "aa"
      refute own_fields_success_title == updated_title

      own_fields_variables = %{
        "experienceId" => experience,
        "ownFields" => %{
          "title" => updated_title
        }
      }

      variables = %{
        "input" => [
          own_fields_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience,
                           "ownFields" => %{
                             "data" => %{
                               "title" => ^updated_title
                             }
                           }
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )
    end

    test "erfolg: Erfahrungs Beschreibung löschen" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        description: description
      } =
        Factory.insert(
          %{
            user_id: user.id,
            description: "df"
          },
          [
            "integer"
          ]
        )

      assert is_binary(description)

      own_fields_success_variable = %{
        "experienceId" => experience_id,
        "ownFields" => %{
          "description" => nil
        }
      }

      variables = %{
        "input" => [
          own_fields_success_variable
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "ownFields" => %{
                             "data" => %{
                               "description" => nil
                             }
                           }
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )
    end

    test "erfolg: Erfahrungs Beschreibung bearbeiten" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        description: description
      } =
        Factory.insert(
          %{
            user_id: user.id,
            description: nil
          },
          [
            "integer"
          ]
        )

      refute is_binary(description)
      bearbetet_beschreibung = "bg"

      own_fields_success_variable = %{
        "experienceId" => experience_id,
        "ownFields" => %{
          "description" => bearbetet_beschreibung
        }
      }

      variables = %{
        "input" => [
          own_fields_success_variable
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "ownFields" => %{
                             "data" => %{
                               "description" => ^bearbetet_beschreibung
                             }
                           }
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )
    end

    test "scheitern: Definition nicht gefunden" do
      bogus_id = @bogus_id
      user = RegFactory.insert()

      %{
        id: experience_id
      } =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => bogus_id,
            "name" => "aa"
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "errors" => %{
                                 "id" => ^bogus_id,
                                 "error" => definition_not_found_error
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(definition_not_found_error)
    end

    test "scheitern: Definition erhebt Ausnahme" do
      user = RegFactory.insert()
      raises_id = "1"

      %{
        id: experience_id
      } =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => raises_id,
            "name" => "aa"
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      log =
        capture_log(fn ->
          assert {
                   :ok,
                   %{
                     data: %{
                       "updateExperiences" => %{
                         "experiences" => [
                           %{
                             "experience" => %{
                               "experienceId" => ^experience_id,
                               "updatedDefinitions" => [
                                 %{
                                   "errors" => %{
                                     "id" => ^raises_id,
                                     "error" => raises_error
                                   }
                                 }
                               ]
                             }
                           }
                         ]
                       }
                     }
                   }
                 } =
                   Absinthe.run(
                     Query.update_experiences(),
                     Schema,
                     variables: variables,
                     context: context(user)
                   )

          assert is_binary(raises_error)
        end)

      assert log =~ "STACK"
    end

    test "scheitern: Definition Name zu klein" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        data_definitions: [%{id: definition0_id} = _definition]
      } =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            # name must be at least 2 chars long
            "name" => "a"
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "errors" => %{
                                 "id" => ^definition0_id,
                                 "name" => definition_name_too_short_error
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(definition_name_too_short_error)
    end

    test "scheitern / erfolg: Definition Name shon nehmen" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            name: definition0_name
          },
          %{
            name: definition1_name
          }
        ]
      } =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer",
            "integer"
          ]
        )

      refute definition0_name == definition1_name

      definition0_name_updated = definition0_name <> "1"

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            # name already taken
            "name" => definition1_name
          },
          %{
            "id" => definition0_id,
            # success
            "name" => definition0_name_updated
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "errors" => %{
                                 "id" => ^definition0_id,
                                 "name" => definition_name_taken_error
                               }
                             },
                             %{
                               "definition" => %{
                                 "id" => ^definition0_id,
                                 "name" => ^definition0_name_updated
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert is_binary(definition_name_taken_error)
    end
  end

  describe "update data definition" do
    # @tag :skip
    test " erfolg: integer to decimal" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      definition0_type_updated = "DECIMAL"
      refute definition0_type == String.downcase(definition0_type_updated)

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            "type" => definition0_type_updated
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "definition" => %{
                                 "id" => ^definition0_id,
                                 "type" => ^definition0_type_updated
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      %{data: data} = EbnisData.get_data_object(data_object0_id)
      [{"decimal", value}] = Map.to_list(data)
      assert is_float(value)
    end

    # @tag :skip
    test " erfolg: decimal to integer" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "decimal"
          ]
        )

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      definition0_type_updated = "INTEGER"
      refute definition0_type == String.downcase(definition0_type_updated)

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            "type" => definition0_type_updated
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "definition" => %{
                                 "id" => ^definition0_id,
                                 "type" => ^definition0_type_updated
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      %{data: data} = EbnisData.get_data_object(data_object0_id)
      [{"integer", value}] = Map.to_list(data)
      assert is_integer(value)
    end

    # @tag :skip
    test " erfolg: date to datetime" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "date"
          ]
        )

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      definition0_type_updated = "DATETIME"
      refute definition0_type == String.downcase(definition0_type_updated)

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            "type" => definition0_type_updated
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "definition" => %{
                                 "id" => ^definition0_id,
                                 "type" => ^definition0_type_updated
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      %{data: data} = EbnisData.get_data_object(data_object0_id)
      assert [{"datetime", %DateTime{}}] = Map.to_list(data)
    end

    # @tag :skip
    test " erfolg: datetime to date" do
      user = RegFactory.insert()

      current = "datetime"
      new = "date"
      definition0_type_updated = String.upcase(new)

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            current
          ]
        )

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      refute definition0_type == new

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            "type" => definition0_type_updated
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "definition" => %{
                                 "id" => ^definition0_id,
                                 "type" => ^definition0_type_updated
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      %{data: data} = EbnisData.get_data_object(data_object0_id)
      assert [{new_from_db, %Date{}}] = Map.to_list(data)
      assert new == new_from_db
    end

    # @tag :skip
    test " erfolg: all to multi_line_text" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          },
          %{
            id: definition1_id,
            type: definition1_type
          },
          %{
            id: definition2_id,
            type: definition2_type
          },
          %{
            id: definition3_id,
            type: definition3_type
          },
          %{
            id: definition4_id,
            type: definition4_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "date",
            "datetime",
            "integer",
            "decimal",
            "single_line_text"
          ]
        )

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id
          },
          %{
            id: data_object1_id
          },
          %{
            id: data_object2_id
          },
          %{
            id: data_object3_id
          },
          %{
            id: data_object4_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      definition_type_updated = "MULTI_LINE_TEXT"
      definition_type_updated_lower = String.downcase(definition_type_updated)

      refute definition0_type == definition_type_updated_lower
      refute definition1_type == definition_type_updated_lower
      refute definition2_type == definition_type_updated_lower
      refute definition3_type == definition_type_updated_lower
      refute definition4_type == definition_type_updated_lower

      definition_ids = [
        definition0_id,
        definition1_id,
        definition2_id,
        definition3_id,
        definition4_id
      ]

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" =>
          Enum.map(
            definition_ids,
            &%{
              "id" => &1,
              "type" => definition_type_updated
            }
          )
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => updated_definitions
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert Enum.map(updated_definitions, fn d ->
               dd = d["definition"]
               {dd["id"], dd["type"]}
             end) == Enum.map(definition_ids, &{&1, definition_type_updated})

      EbnisData.get_data_objects([
        data_object0_id,
        data_object1_id,
        data_object2_id,
        data_object3_id,
        data_object4_id
      ])
      |> Enum.each(fn %{data: data} ->
        assert [{"multi_line_text", v}] = Map.to_list(data)
        assert is_binary(v)
      end)
    end

    # @tag :skip
    test " erfolg: all to single_line_text, except multi_line_text" do
      user = RegFactory.insert()

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          },
          %{
            id: definition1_id,
            type: definition1_type
          },
          %{
            id: definition2_id,
            type: definition2_type
          },
          %{
            id: definition3_id,
            type: definition3_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "date",
            "datetime",
            "integer",
            "decimal"
          ]
        )

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id
          },
          %{
            id: data_object1_id
          },
          %{
            id: data_object2_id
          },
          %{
            id: data_object3_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      definition_type_updated = "SINGLE_LINE_TEXT"
      definition_type_updated_lower = String.downcase(definition_type_updated)

      refute definition0_type == definition_type_updated_lower
      refute definition1_type == definition_type_updated_lower
      refute definition2_type == definition_type_updated_lower
      refute definition3_type == definition_type_updated_lower

      definition_ids = [
        definition0_id,
        definition1_id,
        definition2_id,
        definition3_id
      ]

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" =>
          Enum.map(
            definition_ids,
            &%{
              "id" => &1,
              "type" => definition_type_updated
            }
          )
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => updated_definitions
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      assert Enum.map(updated_definitions, fn d ->
               dd = d["definition"]
               {dd["id"], dd["type"]}
             end) == Enum.map(definition_ids, &{&1, definition_type_updated})

      EbnisData.get_data_objects([
        data_object0_id,
        data_object1_id,
        data_object2_id,
        data_object3_id
      ])
      |> Enum.each(fn %{data: data} ->
        assert [{"single_line_text", v}] = Map.to_list(data)
        assert is_binary(v)
      end)
    end

    # @tag :skip
    test " erfolg: multi_line_text to single_line_text" do
      user = RegFactory.insert()

      current = "multi_line_text"
      new = "single_line_text"
      definition0_type_updated = String.upcase(new)

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            current
          ]
        )

      # 260 chars
      text =
        "1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id,
            data: current_data
          }
        ]
      } =
        _entry =
        EntryFactory.insert(
          %{
            data_objects: [
              %{
                definition_id: definition0_id,
                data: Map.new([{current, text}])
              }
            ]
          },
          experience
        )

      assert current_data[current] == text
      refute definition0_type == new

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            "type" => definition0_type_updated
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "definition" => %{
                                 "id" => ^definition0_id,
                                 "type" => ^definition0_type_updated
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      %{data: data} = EbnisData.get_data_object(data_object0_id)
      assert [{new_from_db, value}] = Map.to_list(data)
      assert new == new_from_db
      assert String.length(value) == 256
    end

    test " erfolg: decimal to integer, entries added with update" do
      user = RegFactory.insert()

      definition_type_updated = "INTEGER"
      definition_type_updated_lower = String.downcase(definition_type_updated)
      new_data_value = 1

      %{
        id: experience_id,
        data_definitions: [
          %{
            id: definition0_id,
            type: definition0_type
          }
        ]
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "decimal"
          ]
        )

      %{
        id: _entry_id,
        data_objects: [
          %{
            id: data_object0_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      refute definition0_type == definition_type_updated_lower

      new_data_for_update = ~s({"#{definition_type_updated_lower}":#{new_data_value}})

      definitions_variables = %{
        "experienceId" => experience_id,
        "updateDefinitions" => [
          %{
            "id" => definition0_id,
            "type" => definition_type_updated
          }
        ],
        "addEntries" => [
          %{
            "dataObjects" => [
              %{
                "definitionId" => definition0_id,
                "data" => new_data_for_update,
                "clientId" => "x"
              }
            ]
          }
        ]
      }

      variables = %{
        "input" => [
          definitions_variables
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "updateExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "experienceId" => ^experience_id,
                           "updatedDefinitions" => [
                             %{
                               "definition" => %{
                                 "id" => ^definition0_id,
                                 "type" => ^definition_type_updated
                               }
                             }
                           ]
                         },
                         "entries" => %{
                           "newEntries" => [
                             %{
                               "entry" => %{
                                 "id" => _,
                                 "dataObjects" => [
                                   %{
                                     "id" => data_object1_id,
                                     "definitionId" => ^definition0_id,
                                     "data" => ^new_data_for_update,
                                     "clientId" => "x"
                                   }
                                 ]
                               }
                             }
                           ]
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.update_experiences(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )

      new_data_from_db0 =
        Map.new([
          {definition_type_updated_lower, 0}
        ])

      assert %{
               data: ^new_data_from_db0
             } = EbnisData.get_data_object(data_object0_id)

      new_data_from_db1 =
        Map.new([
          {definition_type_updated_lower, new_data_value}
        ])

      assert %{
               data: ^new_data_from_db1
             } = EbnisData.get_data_object(data_object1_id)
    end
  end

  describe "delete experiences" do
    # @tag :skip
    test "unauthorized" do
      assert {
               :ok,
               %{
                 data: %{
                   "deleteExperiences" => %{
                     "error" => error
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.delete_experiences(),
                 Schema,
                 variables: %{
                   "input" => ["1"]
                 }
               )

      assert is_binary(error)
    end

    # @tag :skip
    test "invalid ULID id" do
      raises_id = "1"
      user = RegFactory.insert()

      variables = %{
        "input" => [
          raises_id
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "deleteExperiences" => %{
                     "experiences" => [
                       %{
                         "errors" => %{
                           "id" => ^raises_id,
                           "error" => raises_error
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.delete_experiences(),
                 Schema,
                 variables: variables,
                 context:
                   user
                   |> context()
                   |> client_session_context()
                   |> client_token_context()
               )

      assert is_binary(raises_error)
    end

    test "erfahrung nitch gefunden" do
      bogus_id = @bogus_id
      user = RegFactory.insert()

      variables = %{
        "input" => [
          bogus_id
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "deleteExperiences" => %{
                     "experiences" => [
                       %{
                         "errors" => %{
                           "id" => ^bogus_id,
                           "error" => not_found_error
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.delete_experiences(),
                 Schema,
                 variables: variables,
                 context:
                   user
                   |> context()
                   |> client_session_context()
                   |> client_token_context()
               )

      assert is_binary(not_found_error)
    end

    test "erfolg" do
      user = RegFactory.insert()

      %{id: experience_id} =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      variables = %{
        "input" => [
          experience_id
        ]
      }

      assert {
               :ok,
               %{
                 data: %{
                   "deleteExperiences" => %{
                     "experiences" => [
                       %{
                         "experience" => %{
                           "id" => ^experience_id
                         }
                       }
                     ]
                   }
                 }
               }
             } =
               Absinthe.run(
                 Query.delete_experiences(),
                 Schema,
                 variables: variables,
                 context:
                   user
                   |> context()
                   |> client_session_context()
                   |> client_token_context()
               )
    end
  end

  describe "sammeln viele erfahrungen" do
    # @tag :skip
    test "fails for unauthorized user" do
      assert {
               :ok,
               %{
                 errors: [
                   %{
                     message: _
                   }
                 ]
               }
             } =
               Absinthe.run(
                 Query.gets(),
                 Schema
               )
    end

    # @tag :skip
    test "succeeds with pagination only" do
      user = RegFactory.insert()
      _experience4 = %{id: experienceId4} = Factory.insert(user_id: user.id)

      experience1 = Factory.insert(user_id: user.id)
      experience2 = Factory.insert(user_id: user.id)
      experience3 = Factory.insert(user_id: user.id)

      assert {:ok,
              %{
                data: %{
                  "getExperiences" => %{
                    "edges" => edges,
                    "pageInfo" => %{
                      "hasNextPage" => true,
                      "hasPreviousPage" => false,
                      "startCursor" => _,
                      "endCursor" => endCursor
                    }
                  }
                }
              }} =
               Absinthe.run(
                 Query.gets(),
                 Schema,
                 variables: %{
                   "first" => 3
                 },
                 context: context(user)
               )

      assert edges
             |> Enum.flat_map(fn edge ->
               node = edge["node"]

               data_definitions_ids =
                 node["dataDefinitions"]
                 |> Enum.map(& &1["id"])

               Enum.concat([
                 [
                   node["id"]
                 ],
                 data_definitions_ids
               ])
             end)
             |> Enum.sort() ==
               [
                 [
                   experience1.id,
                   experience2.id,
                   experience3.id
                 ],
                 Enum.map(experience1.data_definitions, & &1.id),
                 Enum.map(experience2.data_definitions, & &1.id),
                 Enum.map(experience3.data_definitions, & &1.id)
               ]
               |> Enum.concat()
               |> Enum.sort()

      # next edges
      assert {:ok,
              %{
                data: %{
                  "getExperiences" => %{
                    "edges" => [
                      %{
                        "node" => %{
                          "id" => ^experienceId4
                        }
                      }
                    ],
                    "pageInfo" => %{
                      "hasNextPage" => false,
                      "hasPreviousPage" => true,
                      "startCursor" => cursor1,
                      "endCursor" => cursor2
                    }
                  }
                }
              }} =
               Absinthe.run(
                 Query.gets(),
                 Schema,
                 variables: %{
                   "first" => 3,
                   "after" => endCursor
                 },
                 context: context(user)
               )

      assert cursor1 == cursor2

      assert {:ok,
              %{
                data: %{
                  "getExperiences" => %{
                    "edges" => _edges,
                    "pageInfo" => %{
                      "hasNextPage" => true,
                      "hasPreviousPage" => false,
                      "startCursor" => _,
                      "endCursor" => ^endCursor
                    }
                  }
                }
              }} =
               Absinthe.run(
                 Query.gets(),
                 Schema,
                 variables: %{
                   "last" => 3,
                   "before" => cursor1
                 },
                 context: context(user)
               )
    end

    # @tag :skip
    test "returns []: no experience exists" do
      user = RegFactory.insert()

      variables = %{
        "input" => %{
          "pagination" => %{
            "first" => 2
          }
        }
      }

      assert {:ok,
              %{
                data: %{
                  "getExperiences" => %{
                    "edges" => [],
                    "pageInfo" => %{
                      "hasNextPage" => false,
                      "hasPreviousPage" => false
                    }
                  }
                }
              }} =
               Absinthe.run(
                 Query.gets(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )
    end
  end

  describe "eine erfahrung kriegen" do
    # @tag :skip
    test "fails: unauthenticated" do
      variables = %{
        "id" => "0"
      }

      assert {:ok,
              %{
                errors: [
                  %{
                    message: _
                  }
                ]
              }} =
               Absinthe.run(
                 Query.get(),
                 Schema,
                 variables: variables
               )
    end

    # @tag :skip
    test "fails: experience does not exist" do
      user = RegFactory.insert()

      variables = %{
        "id" => @bogus_id
      }

      assert {:ok,
              %{
                errors: [
                  %{
                    message: _
                  }
                ]
              }} =
               Absinthe.run(
                 Query.get(),
                 Schema,
                 variables: variables,
                 context: context(user)
               )
    end

    # @tag :skip
    test "fails: wrong user" do
      user = RegFactory.insert()
      %{id: id} = Factory.insert(user_id: user.id)

      variables = %{
        "id" => id
      }

      bogus_user = %{id: @bogus_id}

      assert {:ok,
              %{
                errors: [
                  %{
                    message: "Experience definition not found"
                  }
                ]
              }} =
               Absinthe.run(
                 Query.get(),
                 Schema,
                 variables: variables,
                 context: context(bogus_user)
               )
    end

    # @tag :skip
    test "gelingen: eine erfahrung" do
      user = RegFactory.insert()
      experience = Factory.insert(user_id: user.id)
      experience_id = experience.id

      assert {:ok,
              %{
                data: %{
                  "getExperience" => %{
                    "id" => ^experience_id
                  }
                }
              }} =
               Absinthe.run(
                 Query.get(),
                 Schema,
                 variables: %{
                   "id" => experience_id
                 },
                 context: context(user)
               )
    end
  end

  describe "vorholen erfahrungen" do
    # @tag :skip
    test "unauthorized" do
      assert {:ok,
              %{
                errors: [
                  %{
                    message: _
                  }
                ]
              }} =
               Absinthe.run(
                 Query.vorholen_erfahrungen(),
                 Schema,
                 variables: %{
                   "ids" => ["0"],
                   "entryPagination" => %{
                     "first" => 1
                   }
                 }
               )
    end

    # @tag :skip
    test "erhebt Ausnahme für Erfahrung" do
      log_message =
        capture_log(fn ->
          assert {:ok,
                  %{
                    errors: [
                      %{
                        message: _
                      }
                    ]
                  }} =
                   Absinthe.run(
                     Query.vorholen_erfahrungen(),
                     Schema,
                     variables: %{
                       "ids" => ["0"],
                       "entryPagination" => %{
                         "first" => 1
                       }
                     },
                     context:
                       context(%{
                         id: @bogus_id
                       })
                   )
        end)

      assert log_message =~ "STACK"
    end

    # @tag :skip
    test "leer Dinge" do
      assert {:ok,
              %{
                data: %{
                  "preFetchExperiences" => []
                }
              }} =
               Absinthe.run(
                 Query.vorholen_erfahrungen(),
                 Schema,
                 variables: %{
                   "ids" => [@bogus_id],
                   "entryPagination" => %{
                     "first" => 1
                   }
                 },
                 context:
                   context(%{
                     id: @bogus_id
                   })
               )
    end

    # @tag :skip
    test "erfahrungen und einträge, keine seitennummeriergung" do
      user = RegFactory.insert()

      %{
        id: experience_id
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      %{
        id: entry_id,
        data_objects: [
          %{
            id: data_object0_id
          }
        ]
      } = _entry = EntryFactory.insert(%{}, experience)

      assert {:ok,
              %{
                data: %{
                  "preFetchExperiences" => [
                    %{
                      "entries" => %{
                        "edges" => [
                          %{
                            "node" => %{
                              "id" => ^entry_id,
                              "experienceId" => ^experience_id,
                              "dataObjects" => [
                                %{
                                  "id" => ^data_object0_id
                                }
                              ]
                            }
                          }
                        ],
                        "pageInfo" => %{}
                      },
                      "comments" => [],
                      "id" => ^experience_id,
                      "dataDefinitions" => [
                        %{
                          "id" => _
                        }
                      ]
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.vorholen_erfahrungen(),
                 Schema,
                 variables: %{
                   "ids" => [experience_id],
                   "entryPagination" => %{
                     "first" => 1
                   }
                 },
                 context: context(user)
               )
    end

    # @tag :skip
    test "erfahrungen und einträge, mit seitennummeriergung" do
      user = RegFactory.insert()

      %{
        id: experience_id
      } =
        experience =
        Factory.insert(
          %{user_id: user.id},
          [
            "integer"
          ]
        )

      [
        _,
        %{
          id: entry_id,
          data_objects: [
            %{
              id: data_object0_id
            }
          ]
        }
      ] =
        1..2
        |> Enum.map(fn _ ->
          EntryFactory.insert(%{}, experience)
        end)

      assert {:ok,
              %{
                data: %{
                  "preFetchExperiences" => [
                    %{
                      "entries" => %{
                        "edges" => [
                          %{
                            "node" => %{
                              "id" => ^entry_id,
                              "experienceId" => ^experience_id,
                              "dataObjects" => [
                                %{
                                  "id" => ^data_object0_id
                                }
                              ]
                            }
                          }
                        ],
                        "pageInfo" => %{
                          "hasPreviousPage" => false,
                          "hasNextPage" => true
                        }
                      },
                      "id" => ^experience_id,
                      "dataDefinitions" => [
                        %{
                          "id" => _
                        }
                      ]
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.vorholen_erfahrungen(),
                 Schema,
                 variables: %{
                   "ids" => [experience_id],
                   "entryPagination" => %{
                     "first" => 1
                   }
                 },
                 context: context(user)
               )
    end

    # @tag :skip
    test "fetch when comments present" do
      user = RegFactory.insert()

      %{
        id: experience_id
      } =
        _experience =
        Factory.insert(
          %{
            user_id: user.id,
            comment_text: "aa"
          },
          [
            "integer"
          ]
        )

      assert {:ok,
              %{
                data: %{
                  "preFetchExperiences" => [
                    %{
                      "comments" => [
                        %{
                          "id" => _,
                          "text" => "aa"
                        }
                      ],
                      "id" => ^experience_id,
                      "dataDefinitions" => [
                        %{
                          "id" => _
                        }
                      ]
                    }
                  ]
                }
              }} =
               Absinthe.run(
                 Query.vorholen_erfahrungen(),
                 Schema,
                 variables: %{
                   "ids" => [experience_id],
                   "entryPagination" => %{
                     "first" => 1
                   }
                 },
                 context: context(user)
               )
    end
  end

  defp context(user), do: %{current_user: user}

  defp client_session_context(context_val, val \\ "s") do
    Map.put(context_val, :client_session, val)
  end

  defp client_token_context(context_val, val \\ "t") do
    Map.put(context_val, :client_token, val)
  end
end
