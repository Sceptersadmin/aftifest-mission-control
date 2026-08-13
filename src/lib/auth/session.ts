import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export async function getSessionUser() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) return null;
  return data.user;
}

export async function requireSessionUser() {
  const user = await getSessionUser();
  if (!user) redirect("/login");
  return user;
}

export async function requireOrganizationPermission(permission: string) {
  const user = await requireSessionUser();
  const supabase = await createClient();
  const { data: memberships } = await supabase.from("organization_members").select("organization_id").eq("profile_id", user.id).eq("status", "active");
  const organizationId = memberships?.[0]?.organization_id as string | undefined;
  if (!organizationId) redirect("/");
  const { data: allowed } = await supabase.rpc("has_permission", { target_organization_id: organizationId, requested_permission: permission });
  if (allowed !== true) redirect("/");
  return { user, organizationId };
}
