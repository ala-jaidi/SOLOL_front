export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      chat_messages: {
        Row: {
          content: string
          created_at: string | null
          id: string
          is_user: boolean
          status: string
          user_id: string
        }
        Insert: {
          content: string
          created_at?: string | null
          id?: string
          is_user?: boolean
          status?: string
          user_id: string
        }
        Update: {
          content?: string
          created_at?: string | null
          id?: string
          is_user?: boolean
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chat_messages_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      foot_metrics: {
        Row: {
          confidence: number
          created_at: string | null
          id: string
          largeur: number
          longueur: number
          session_id: string
          side: string
          updated_at: string | null
        }
        Insert: {
          confidence: number
          created_at?: string | null
          id?: string
          largeur: number
          longueur: number
          session_id: string
          side: string
          updated_at?: string | null
        }
        Update: {
          confidence?: number
          created_at?: string | null
          id?: string
          largeur?: number
          longueur?: number
          session_id?: string
          side?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "foot_metrics_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      foot_scans: {
        Row: {
          angle: string
          created_at: string | null
          id: string
          session_id: string
          side_view: string
          top_view: string
          updated_at: string | null
        }
        Insert: {
          angle: string
          created_at?: string | null
          id?: string
          session_id: string
          side_view: string
          top_view: string
          updated_at?: string | null
        }
        Update: {
          angle?: string
          created_at?: string | null
          id?: string
          session_id?: string
          side_view?: string
          top_view?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "foot_scans_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      medical_questionnaires: {
        Row: {
          condition: string | null
          created_at: string | null
          id: string
          question: string
          reponse: string
          session_id: string
          updated_at: string | null
        }
        Insert: {
          condition?: string | null
          created_at?: string | null
          id?: string
          question: string
          reponse: string
          session_id: string
          updated_at?: string | null
        }
        Update: {
          condition?: string | null
          created_at?: string | null
          id?: string
          question?: string
          reponse?: string
          session_id?: string
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "medical_questionnaires_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          body: string
          created_at: string | null
          id: string
          read: boolean | null
          title: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string | null
          id?: string
          read?: boolean | null
          title: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string | null
          id?: string
          read?: boolean | null
          title?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      patients: {
        Row: {
          adresse: string
          age: number
          avatar_url: string | null
          created_at: string | null
          date_naissance: string
          email: string
          id: string
          nom: string
          organisation: string
          poids: number
          pointure: string
          prenom: string
          sexe: string
          specialite: string
          taille: number
          telephone: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          adresse: string
          age: number
          avatar_url?: string | null
          created_at?: string | null
          date_naissance: string
          email: string
          id?: string
          nom: string
          organisation: string
          poids: number
          pointure: string
          prenom: string
          sexe: string
          specialite: string
          taille: number
          telephone: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          adresse?: string
          age?: number
          avatar_url?: string | null
          created_at?: string | null
          date_naissance?: string
          email?: string
          id?: string
          nom?: string
          organisation?: string
          poids?: number
          pointure?: string
          prenom?: string
          sexe?: string
          specialite?: string
          taille?: number
          telephone?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "patients_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      sessions: {
        Row: {
          created_at: string | null
          id: string
          patient_id: string
          status: string
          updated_at: string | null
          valid: boolean
        }
        Insert: {
          created_at?: string | null
          id?: string
          patient_id: string
          status?: string
          updated_at?: string | null
          valid?: boolean
        }
        Update: {
          created_at?: string | null
          id?: string
          patient_id?: string
          status?: string
          updated_at?: string | null
          valid?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "sessions_patient_id_fkey"
            columns: ["patient_id"]
            isOneToOne: false
            referencedRelation: "patients"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          adresse: string | null
          age: number | null
          avatar_url: string | null
          created_at: string | null
          date_naissance: string | null
          email: string
          id: string
          nom: string
          organisation: string | null
          poids: number | null
          pointure: string | null
          prenom: string | null
          role: string
          sexe: string | null
          specialite: string | null
          taille: number | null
          telephone: string | null
          updated_at: string | null
        }
        Insert: {
          adresse?: string | null
          age?: number | null
          avatar_url?: string | null
          created_at?: string | null
          date_naissance?: string | null
          email: string
          id: string
          nom: string
          organisation?: string | null
          poids?: number | null
          pointure?: string | null
          prenom?: string | null
          role?: string
          sexe?: string | null
          specialite?: string | null
          taille?: number | null
          telephone?: string | null
          updated_at?: string | null
        }
        Update: {
          adresse?: string | null
          age?: number | null
          avatar_url?: string | null
          created_at?: string | null
          date_naissance?: string | null
          email?: string
          id?: string
          nom?: string
          organisation?: string | null
          poids?: number | null
          pointure?: string | null
          prenom?: string | null
          role?: string
          sexe?: string | null
          specialite?: string | null
          taille?: number | null
          telephone?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      insert_user_to_auth: {
        Args: { email: string; password: string }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
