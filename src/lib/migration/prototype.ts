import {createHash} from "node:crypto";
import {z} from "zod";
const record=z.record(z.string(),z.unknown());
const dataSchema=z.object({settings:z.object({workspaceName:z.string(),eventStart:z.string(),eventEnd:z.string()}),departments:z.array(record).default([]),tasks:z.array(record).default([]),reports:z.array(record).default([]),content:z.array(record).default([]),milestones:z.array(record).default([]),resources:z.array(record).default([]),sponsors:z.array(record).default([]),decisions:z.array(record).default([])}).strict();
const sourceSchema=z.union([dataSchema,z.object({aftifestCommandData:dataSchema}).strict()]);
export type PrototypeData=z.infer<typeof dataSchema>;
export type ImportItem={sourceType:string;sourceKey:string;targetType:string;payload:Record<string,unknown>;mapping:Record<string,string>;status:"ready"|"deferred";notes:string};
export type MigrationPreview={digest:string;classification: "SAMPLE / UNAPPROVED";detectedSchema:string;counts:Record<string,number>;warnings:string[];unsupportedFields:string[];invalidRelationships:string[];duplicateCandidates:string[];peopleMappings:{name:string;state:"UNMAPPED PERSON"}[];items:ImportItem[];data:PrototypeData};
const text=(v:unknown)=>typeof v==="string"?v.trim():String(v??"").trim();
const sourceKey=(kind:string,row:Record<string,unknown>,index:number)=>`${kind}:${text(row.id||row.name||row.organization||row.title||index)}`;
export function previewPrototypeMigration(raw:string):MigrationPreview{
 if(Buffer.byteLength(raw,"utf8")>2_000_000)throw new Error("MIGRATION_FILE_TOO_LARGE");
 let parsed:unknown;try{parsed=JSON.parse(raw)}catch{throw new Error("INVALID_PROTOTYPE_JSON")}
 const source=sourceSchema.parse(parsed);const wrapped="aftifestCommandData" in source;const data=wrapped?source.aftifestCommandData:source;
 const counts:Record<string,number>={};for(const [key,value]of Object.entries(data))if(Array.isArray(value))counts[key]=value.length;
 const warnings=["Event dates require reconciliation.","Festival pillar count requires reconciliation.","Departments and department leads are unapproved.","Sponsor organizations and financial values are illustrative and unverified.","Placeholder resource URLs are not imported.","Deadlines may be outdated and are retained only in provenance.","Prototype readiness values are provenance only; Operational Readiness remains PROVISIONAL.","Governance decisions and approval authorities remain SAMPLE / UNAPPROVED.","People and ownership references require explicit member mapping."];
 const departments=new Map<string,string>();data.departments.forEach((row,index)=>{const key=sourceKey("departments",row,index);departments.set(text(row.name),key);departments.set(text(row.id),key)});
 const items:ImportItem[]=[];const add=(sourceType:string,targetType:string,row:Record<string,unknown>,index:number,status:"ready"|"deferred"="ready",notes="SAMPLE / UNAPPROVED")=>items.push({sourceType,sourceKey:sourceKey(sourceType,row,index),targetType,payload:row,mapping:{},status,notes});
 data.departments.forEach((r,i)=>add("departments","department",r,i));
 data.tasks.forEach((r,i)=>{const match=departments.get(text(r.dept));const item:ImportItem={sourceType:"tasks",sourceKey:sourceKey("tasks",r,i),targetType:"task",payload:r,mapping:match?{departmentKey:match}:{},status:match?"ready":"deferred",notes:match?"Owner remains UNMAPPED PERSON":"Missing department mapping"};items.push(item)});
 data.reports.forEach((r,i)=>add("reports","report",r,i,"deferred","Reporter, reporting period, and department member mapping required"));
 data.content.forEach((r,i)=>add("content","content_item",r,i));data.sponsors.forEach((r,i)=>add("sponsors","sponsor",r,i));data.milestones.forEach((r,i)=>add("milestones","milestone",r,i));data.decisions.forEach((r,i)=>add("decisions","decision",r,i));data.resources.forEach((r,i)=>add("resources","resource",r,i));
 const people=[...new Set([...data.departments.map(x=>text(x.lead)),...data.tasks.map(x=>text(x.owner)),...data.reports.map(x=>text(x.reporter)),...data.content.map(x=>text(x.owner)),...data.sponsors.map(x=>text(x.owner)),...data.decisions.map(x=>text(x.owner))].filter(Boolean))].map(name=>({name,state:"UNMAPPED PERSON" as const}));
 const keys=new Set<string>();const duplicates:string[]=[];for(const item of items){if(keys.has(item.sourceKey))duplicates.push(item.sourceKey);keys.add(item.sourceKey)}
 return{digest:createHash("sha256").update(raw).digest("hex"),classification:"SAMPLE / UNAPPROVED",detectedSchema:wrapped?"aftifestCommandData/wrapped-v1":"aftifestCommandData/export-v1",counts,warnings,unsupportedFields:["department.members","task.owner","report.reporter","content.owner","sponsor.owner","decision.owner"],invalidRelationships:items.filter(x=>x.status==="deferred").map(x=>`${x.sourceKey}: ${x.notes}`),duplicateCandidates:duplicates,peopleMappings:people,items,data};
}
