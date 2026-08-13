import { NextResponse } from "next/server";

export function GET() {
  return NextResponse.json({ status: "ok", phase: 1, productionInfrastructure: false });
}
