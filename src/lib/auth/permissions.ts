export const PERMISSIONS = [
  "workspace.admin", "department.read", "department.manage", "task.read",
  "task.manage_assigned", "task.manage_department", "report.submit", "report.review",
  "content.read", "content.manage", "sponsor.read", "sponsor.manage", "decision.read",
  "decision.propose", "decision.approve", "governance.read_restricted", "resource.read",
  "resource.manage", "brain.read", "brain.manage", "agent.read", "agent.configure",
  "audit.read",
] as const;

export type Permission = (typeof PERMISSIONS)[number];

export type AuthorizationContext = {
  actorId: string;
  organizationId: string;
  membershipId: string;
  permissions: ReadonlySet<Permission>;
  departmentIds: ReadonlySet<string>;
};

export function hasPermission(context: AuthorizationContext, permission: Permission) {
  return context.permissions.has("workspace.admin") || context.permissions.has(permission);
}

export function requirePermission(context: AuthorizationContext, permission: Permission) {
  if (!hasPermission(context, permission)) {
    throw new Error(`FORBIDDEN:${permission}`);
  }
}

export function canAccessDepartment(context: AuthorizationContext, departmentId: string) {
  return hasPermission(context, "department.manage") || context.departmentIds.has(departmentId);
}
