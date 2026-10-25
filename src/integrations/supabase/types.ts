export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18";
  };
  public: {
    Tables: {
      agents: {
        Row: {
          color: string;
          created_at: string;
          id: string;
          name: string;
          provider: string;
          role: string;
          skills: string[];
          system_prompt: string;
          user_id: string;
        };
        Insert: {
          color?: string;
          created_at?: string;
          id?: string;
          name: string;
          provider?: string;
          role?: string;
          skills?: string[];
          system_prompt?: string;
          user_id?: string;
        };
        Update: {
          color?: string;
          created_at?: string;
          id?: string;
          name?: string;
          provider?: string;
          role?: string;
          skills?: string[];
          system_prompt?: string;
          user_id?: string;
        };
        Relationships: [];
      };
      ai_settings: {
        Row: {
          custom_api_key: string;
          custom_base_url: string;
          custom_model: string;
          default_provider: string;
          ollama_model: string;
          ollama_url: string;
          updated_at: string;
          user_id: string;
        };
        Insert: {
          custom_api_key?: string;
          custom_base_url?: string;
          custom_model?: string;
          default_provider?: string;
          ollama_model?: string;
          ollama_url?: string;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          custom_api_key?: string;
          custom_base_url?: string;
          custom_model?: string;
          default_provider?: string;
          ollama_model?: string;
          ollama_url?: string;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [];
      };
      app_owner: {
        Row: {
          created_at: string;
          id: number;
          user_id: string;
        };
        Insert: {
          created_at?: string;
          id?: number;
          user_id: string;
        };
        Update: {
          created_at?: string;
          id?: number;
          user_id?: string;
        };
        Relationships: [];
      };
      artifacts: {
        Row: {
          agent_name: string;
          content: string;
          created_at: string;
          id: string;
          path: string;
          run_id: string | null;
          updated_at: string;
          user_id: string;
        };
        Insert: {
          agent_name?: string;
          content: string;
          created_at?: string;
          id?: string;
          path: string;
          run_id?: string | null;
          updated_at?: string;
          user_id?: string;
        };
        Update: {
          agent_name?: string;
          content?: string;
          created_at?: string;
          id?: string;
          path?: string;
          run_id?: string | null;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "artifacts_run_id_fkey";
            columns: ["run_id"];
            isOneToOne: false;
            referencedRelation: "runs";
            referencedColumns: ["id"];
          },
        ];
      };
      customizations: {
        Row: {
          config: Json;
          history: Json;
          id: string;
          updated_at: string;
          user_id: string;
        };
        Insert: {
          config?: Json;
          history?: Json;
          id?: string;
          updated_at?: string;
          user_id: string;
        };
        Update: {
          config?: Json;
          history?: Json;
          id?: string;
          updated_at?: string;
          user_id?: string;
        };
        Relationships: [];
      };
      knowledge: {
        Row: {
          agent_name: string;
          content: string;
          created_at: string;
          id: string;
          topic: string;
          user_id: string;
        };
        Insert: {
          agent_name?: string;
          content: string;
          created_at?: string;
          id?: string;
          topic: string;
          user_id?: string;
        };
        Update: {
          agent_name?: string;
          content?: string;
          created_at?: string;
          id?: string;
          topic?: string;
          user_id?: string;
        };
        Relationships: [];
      };
      run_logs: {
        Row: {
          agent_name: string;
          created_at: string;
          id: number;
          kind: string;
          message: string;
          run_id: string;
          user_id: string;
        };
        Insert: {
          agent_name?: string;
          created_at?: string;
          id?: number;
          kind?: string;
          message: string;
          run_id: string;
          user_id?: string;
        };
        Update: {
          agent_name?: string;
          created_at?: string;
          id?: number;
          kind?: string;
          message?: string;
          run_id?: string;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "run_logs_run_id_fkey";
            columns: ["run_id"];
            isOneToOne: false;
            referencedRelation: "runs";
            referencedColumns: ["id"];
          },
        ];
      };
      runs: {
        Row: {
          finished_at: string | null;
          id: string;
          input: string;
          output: string | null;
          started_at: string;
          status: string;
          user_id: string;
          workflow_id: string | null;
          workflow_name: string;
        };
        Insert: {
          finished_at?: string | null;
          id?: string;
          input?: string;
          output?: string | null;
          started_at?: string;
          status?: string;
          user_id?: string;
          workflow_id?: string | null;
          workflow_name?: string;
        };
        Update: {
          finished_at?: string | null;
          id?: string;
          input?: string;
          output?: string | null;
          started_at?: string;
          status?: string;
          user_id?: string;
          workflow_id?: string | null;
          workflow_name?: string;
        };
        Relationships: [
          {
            foreignKeyName: "runs_workflow_id_fkey";
            columns: ["workflow_id"];
            isOneToOne: false;
            referencedRelation: "workflows";
            referencedColumns: ["id"];
          },
        ];
      };
      workflows: {
        Row: {
          created_at: string;
          description: string;
          id: string;
          name: string;
          stages: Json;
          user_id: string;
        };
        Insert: {
          created_at?: string;
          description?: string;
          id?: string;
          name: string;
          stages?: Json;
          user_id?: string;
        };
        Update: {
          created_at?: string;
          description?: string;
          id?: string;
          name?: string;
          stages?: Json;
          user_id?: string;
        };
        Relationships: [];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      claim_owner: { Args: never; Returns: boolean };
      is_owner: { Args: never; Returns: boolean };
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema["Tables"] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    keyof DefaultSchema["Tables"] | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    keyof DefaultSchema["Enums"] | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    keyof DefaultSchema["CompositeTypes"] | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {},
  },
} as const;
