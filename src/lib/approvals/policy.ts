import type { Permission } from "@/lib/auth/permissions";

export type ApprovalRule = {
  id: string;
  organizationId: string;
  action: string;
  targetType: string;
  requiredPermission: Permission;
  eligibleRoleIds: readonly string[];
  minimumApprovals: number;
  active: boolean;
};

export type ApprovalState = "not_required" | "pending" | "approved" | "rejected" | "expired";

export function evaluateApproval(rule: ApprovalRule | null, approvedRoleIds: ReadonlySet<string>): ApprovalState {
  if (!rule?.active) return "not_required";
  const eligibleApprovals = rule.eligibleRoleIds.filter((roleId) => approvedRoleIds.has(roleId));
  return new Set(eligibleApprovals).size >= rule.minimumApprovals ? "approved" : "pending";
}
