/**********************************************************************
artefact name :- f_sls_ord_sched
description   :- f_sls_ord_sched sql generated via multi-pass CTE pipeline
----------------------------------------------------------------------
change log
version :   date :        description :                       changed by
----------------------------------------------------------------------
0.0         2026-07-16    auto-generated multi-pass            ai_agent
**********************************************************************/

with
vbep_bmeng as (
    select
    vbep.vbeln,
    vbep.posnr,
    sum(vbep.bmeng) as calculated_bmeng
from
    vbep
group by
    vbep.vbeln,
    vbep.posnr
),
uom_conversion as (
    select 
    vbep.vbeln,
    vbep.posnr,
    vbep.bmeng as order_qty_order_uom,
    case 
        when vbep.vrkme = vbap.meins 
        then vbep.bmeng
        else (marm.umrez / marm.umren) * vbep.bmeng
    end as order_qty_primary_uom,
    vbap.trim(vrkme) as g_order_uom_cd,
    vbap.trim(meins) as g_primary_uom_cd,
    case 
        when exists (
            select 1 
            from mska 
            where mska.vbeln = vbep.vbeln 
            and mska.posnr = vbep.posnr
        ) 
        then coalesce(mska.kalab, 0) + coalesce(mska.kains, 0) + coalesce(mska.kaspe, 0) + coalesce(mska.kavla, 0) + coalesce(mska.kavin, 0) + coalesce(mska.kavsp, 0)
        else coalesce(g_shipped_qty_primary_uom, 0)
    end as g_allocated_qty_primary_uom,
    case 
        when vbap.fkrel in ('A', 'H', 'J', 'K', 'M', 'O', 'P', 'Q', 'R', 'T', 'U', 'V', 'W') 
        then round(coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0), 4)
        when trim(vbap.fkrel) = '' 
        then 0
        else round(
            coalesce(order_qty_primary_uom, 0) - 
            case 
                when lst.shipped_qty <> 0 then lst.shipped_qty
                when lst.shipped_qty = 0 and inv.invoice_qty <> 0 then inv.invoice_qty
                else 0
            end, 0
        )
    end - coalesce(cancel_qty_primary_uom, 0) as g_open_qty_primary_uom
from 
    vbep
left join vbap 
    on vbep.vbeln = vbap.vbeln 
    and vbep.posnr = vbap.posnr
left join marm 
    on vbap.matnr = marm.matnr 
    and vbep.vrkme = marm.meinh
left join mska 
    on mska.vbeln = vbep.vbeln 
    and mska.posnr = vbep.posnr
left join lst 
    on lst.vbeln = vbep.vbeln 
    and lst.posnr = vbep.posnr
left join inv 
    on inv.vbeln = vbep.vbeln 
    and inv.posnr = vbep.posnr
),
vbfa_dedup as (
    select 
    vbeln,
    posnr,
    fklmg,
    row_number() over (
        partition by vbeln, posnr 
        order by erdat desc, erzet desc, fklmg desc
    ) as row_num
from 
    vbfa
where 
    fklmg > 0
),
order_schedule as (
    select 
    vbep.etenr as g_delivery_schedule_line_nbr,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    sum(vbep_bmeng.confirmed_qty) over (
        partition by vbep.vbeln, vbep.posnr 
        order by vbep.mbdat
    ) as g_running_total_qty
from 
    vbep_bmeng
left join 
    vbep 
    on vbep_bmeng.vbeln = vbep.vbeln 
    and vbep_bmeng.posnr = vbep.posnr
),
order_shipment as (
    select
    vbfa_dedup.vbelv,
    vbfa_dedup.vbeln,
    vbfa_dedup.posnn,
    vbfa_dedup.posnv,
    vbfa_dedup.vbtyp_n,
    vbfa_dedup.rfmng as g_shipped_qty_primary_uom,
    vbfa_dedup.erdat as g_last_actual_ship_dt_yyyymmdd,
    case 
        when trim(vbap.werks) = '0070' then vbak.zz_ship_by
        else case 
            when zosdates.lddat is not null then zosdates.lddat
            else coalesce(
                case 
                    when order_schedule.original_promised_ship_dt_yyyymmdd is null then vbep.edatu
                    else order_schedule.original_promised_ship_dt_yyyymmdd
                end, 
                null
            )
        end
    end as g_original_promised_ship_dt_yyyymmdd,
    case 
        when trim(vbap.werks) = '0070' then vbak.zz_ship_by
        else trim(vbep.edatu)
    end as g_promised_ship_dt_yyyymmdd,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd
from vbfa_dedup
left join vbep on vbfa_dedup.vbeln = vbep.vbeln and vbfa_dedup.posnn = vbep.posnr
left join vbap on vbep.vbeln = vbap.vbeln and vbep.posnr = vbap.posnr
left join vbak on vbep.vbeln = vbak.vbeln
left join zosdates on vbep.vbeln = zosdates.vbeln and vbep.posnr = zosdates.posnr
left join order_schedule on vbep.vbeln = order_schedule.vbeln and vbep.posnr = order_schedule.posnr
),
last_shipped_dt as (
    select 
    schedule_id,
    first_value(actual_ship_date) over (
        partition by schedule_id 
        order by actual_ship_date desc
    ) as g_last_actual_ship_dt_yyyymmdd
from 
    order_shipment
),
order_invoice as (
    select 
    vbep.vbeln,
    vbep.posnr,
    first_value(vbfa.erdat) over (
        partition by vbep.vbeln, vbep.posnr 
        order by vbfa.erdat desc
    ) as g_invoice_dt_yyyymmdd,
    sum(vbfa.bmeng) over (
        partition by vbep.vbeln, vbep.posnr
    ) as g_invoice_qty
from 
    vbep
left join vbfa 
    on vbep.vbeln = vbfa.vbeln 
    and vbep.posnr = vbfa.posnr
where 
    vbfa.vbtyp = 'M'
),
tcurf_dedup as (
    select 
    tcurf.ffact,
    tcurf.tfact,
    tcurf.kurst,
    tcurf.datab,
    tcurf.datbi,
    row_number() over (
        partition by tcurf.ffact, tcurf.tfact, tcurf.kurst 
        order by tcurf.datbi desc
    ) as row_num
from 
    tcurf
where 
    tcurf.datab <= current_date and tcurf.datbi >= current_date
),
final_joined as (
    select
  concat_ws('|', 'gbl', t001.bukrs) as co_key,
  case 
    when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
    then mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp
    else coalesce(last_shipped_dt.shipped_qty_primary_uom, 0)
  end as g_allocated_qty_primary_uom,
  cast(null as string) as g_availability_dt_yyyymmdd,
  case 
    when vbap.posnr is not null 
    then (select bp.kunnr from vbpa bp where bp.vbeln = vbep.vbeln and bp.posnr = vbap.posnr and bp.parvw = 'RE/BP' limit 1)
    else (select bp.kunnr from vbpa bp where bp.vbeln = vbep.vbeln and bp.parvw = 'RE/BP' limit 1)
  end as g_bill_to_customer_nbr,
  case 
    when trim(vbap.abgru) = '' then null
    when vbap.aedat = 0 then vbap.erdat
    else vbap.aedat
  end as g_cancel_dt_yyyymmdd,
  cast(null as string) as g_cancel_qty_primary_uom, -- TODO: review mapping
  case 
    when trim(t001.waers) = 'RMB' then 'CNY'
    else trim(t001.waers)
  end as g_company_currency_cd,
  vbap.matnr as g_customer_item_nbr,
  cast(null as string) as g_customer_po_line_nbr,
  case 
    when vbap.posnr is not null 
    then (select po.vbeln from vbpa po where po.vbeln = vbep.vbeln and po.posnr = vbap.posnr limit 1)
    else (select po.vbeln from vbpa po where po.vbeln = vbep.vbeln limit 1)
  end as g_customer_po_nbr,
  cast(null as string) as g_customer_po_type, -- TODO: review mapping
  case 
    when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') 
    then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
    when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') 
    then trim(vbep.request_dt)
    else vbep.edatu
  end as g_customer_request_dt_yyyymmdd,
  vbep.etenr as g_delivery_schedule_line_nbr,
  case 
    when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
    else 'no'
  end as g_flag_consignment_order,
  case 
    when vbap.uepos is not null and vbap.uepos <> 0 then 'yes'
    else 'no'
  end as g_flag_has_parent,
  case 
    when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
    then 'yes'
    else 'no'
  end as g_flag_inventory_fully_allocated,
  case 
    when vbap.posnr = vbap.uepos then 'yes'
    else 'no'
  end as g_flag_is_parent,
  case 
    when kna1.ktokd in ('ZSUB', 'IC3P') or knvv.kdgrp in ('05', '06', '07') then 'yes'
    else 'no'
  end as g_flag_is_transfer_order,
  case 
    when trim(vbak.vbtyp) in ('A', 'B', 'D') then 'no'
    when trim(vbup.lfsta) in ('A', 'B', 'C') and mara.mtart in ('DIEN', 'NSTK', 'SERV', 'ZSRV') then 'no'
    when trim(vbup.lfsta) = '' or vbup.lfsta is null then 'no'
    else 'yes'
  end as g_flag_material_transacted,
  case 
    when vbep.lifsp <> '' then 'yes'
    when vbak.lifsk <> '' then 'yes'
    when vbuk.cmgst in ('B', 'C') then 'yes'
    else 'no'
  end as g_flag_on_hold,
  case 
    when vbak.autlf = 'X' then 'no'
    when coalesce(cancel_qty_primary_uom, 0) = coalesce(order_qty_primary_uom, 0) then 'no'
    when coalesce(open_qty_primary_uom, 0) <= 0 then 'no'
    else 'yes'
  end as g_flag_open_to_ship,
  case 
    when vbak.vbtyp in ('H', 'T') then 'yes'
    else 'no'
  end as g_flag_return,
  case 
    when coalesce(order_qty_primary_uom, 0) = 0 then 'no'
    when trim(vbak.vbtyp) in ('A', 'B', 'D') then 'no'
    when trim(tvap.prsfd) = 'X' then 'yes'
    else 'no'
  end as g_flag_revenue_recognition,
  cast(null as string) as g_inco_terms, -- TODO: review mapping
  cast(null as string) as g_invoice_dt_yyyymmdd, -- TODO: review mapping
  vbap.matnr as g_item_nbr,
  cast(null as string) as g_last_actual_ship_dt_yyyymmdd, -- TODO: review mapping
  case 
    when upper(trim(vbup.gbsta)) = 'A' then 'NOT YET PROCESSED'
    when upper(trim(vbup.gbsta)) = 'B' then 'PARTIALLY PROCESSED'
    when upper(trim(vbup.gbsta)) = 'C' then 'COMPLETELY PROCESSED'
    else 'NOT RELEVANT'
  end as g_line_status_cd,
  case 
    when order_type = 'DEMO' and ship_lines.sttrg = '7' then 0
    when tvap.fkrel in ('A', 'H', 'J', 'K', 'M', 'O', 'P', 'Q', 'R', 'T', 'U', 'V', 'W') 
    then round(coalesce(order_qty_primary_uom, 0) - coalesce(last_shipped_dt.shipped_qty, 0), 4)
    when trim(tvap.fkrel) = '' then 0
    else round(coalesce(order_qty_primary_uom, 0) - coalesce(last_shipped_dt.shipped_qty, 0) - coalesce(cancel_qty_primary_uom, 0), 4)
  end as g_open_qty_primary_uom,
  cast(null as string) as g_order_category, -- TODO: review mapping
  t001k.bukrs as g_order_company_cd,
  case 
    when trim(vbak.waerk) = 'RMB' then 'CNY'
    else trim(vbak.waerk)
  end as g_order_currency_cd,
  vbap.erdat as g_order_dt_yyyymmdd,
  vbep.posnr as g_order_line_nbr,
  vbep.vbeln as g_order_nbr,
  vbep.wmeng as g_order_qty_order_uom,
  case 
    when vbep.vrkme = vbap.meins then vbep.bmeng
    else (marm.umrez / marm.umren) * vbep.bmeng
  end as g_order_qty_primary_uom,
  vbak.auart as g_order_type,
  trim(vbap.vrkme) as g_order_uom_cd,
  vbep.edatu as g_original_customer_request_dt_yyyymmdd,
  vbep.edatu as g_original_promised_ship_dt_yyyymmdd,
  vbap.uepos as g_parent_order_line_nbr,
  cast(null as string) as g_payment_terms, -- TODO: review mapping
  vbap.werks as g_plant_cd,
  trim(vbap.meins) as g_primary_uom_cd,
  case 
    when trim(vbap.werks) = '0070' then vbak.zz_ship_by
    else trim(vbep.edatu)
  end as g_promised_ship_dt_yyyymmdd,
  vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
  case 
    when vbap.posnr is not null 
    then (select we.kunnr from vbpa we where we.vbeln = vbep.vbeln and we.posnr = vbap.posnr and we.parvw = 'WE' limit 1)
    else (select we.kunnr from vbpa we where we.vbeln = vbep.vbeln and we.parvw = 'WE' limit 1)
  end as g_ship_to_customer_nbr,
  datediff(vbep.mbdat, vbep.edatu) as g_ship_to_delivery_days,
  cast(null as string) as g_shipment_mode, -- TODO: review mapping
  coalesce(last_shipped_dt.shipped_qty_primary_uom, 0) as g_shipped_qty_primary_uom,
  'gbl' as g_source_system_cd,
  cast(null as string) as g_unit_cost_company_currency_primary_uom, -- TODO: review mapping
  cast(null as string) as g_unit_price_company_currency_primary_uom, -- TODO: review mapping
  cast(null as string) as g_unit_price_order_currency_primary_uom, -- TODO: review mapping
  concat_ws('|', 'gbl', vbap.werks) as plant_key,
  concat_ws('|', 'gbl', vbap.matnr) as prod_key,
  concat_ws('|', 'gbl', vbap.matnr, vbap.werks) as prod_plant_key,
  concat_ws('|', 'gbl', t001k.bukrs, vbak.auart, vbep.vbeln) as sls_ord_key,
  concat_ws('|', 'gbl', t001k.bukrs, vbak.auart, vbep.vbeln, vbep.posnr, vbep.etenr) as sls_ord_sched_key,
  cast(null as string) as flag_is_blanket -- TODO: review mapping
from vbep_bmeng
left join uom_conversion on vbep_bmeng.vbeln = uom_conversion.vbeln and vbep_bmeng.posnr = uom_conversion.posnr
left join order_schedule on vbep_bmeng.vbeln = order_schedule.vbeln and vbep_bmeng.posnr = order_schedule.posnr
left join last_shipped_dt on vbep_bmeng.vbeln = last_shipped_dt.vbeln and vbep_bmeng.posnr = last_shipped_dt.posnr
left join order_invoice on vbep_bmeng.vbeln = order_invoice.vbeln and vbep_bmeng.posnr = order_invoice.posnr
left join tcurf_dedup on trim(tcurf_dedup.yr_mth_nbr) = trim(order_schedule.fscl_yr_prd_nbr) and trim(tcurf_dedup.to_curncy_cd) = trim(vbak.waerk) and trim(tcurf_dedup.from_curncy_cd) = case when trim(upper(t001.waers)) = 'RMB' then 'CNY' else trim(upper(t001.waers)) end
left join vbap on vbep_bmeng.vbeln = vbap.vbeln and vbep_bmeng.posnr = vbap.posnr
left join marm on vbap.matnr = marm.matnr and vbep_bmeng.vrkme = marm.meinh
left join mbew on vbap.matnr = mbew.matnr and vbap.werks = mbew.bwkey and mbew.mandt = '100' and trim(mbew.bwtar) = ''
left join vbak on vbep_bmeng.vbeln = vbak.vbeln
left join t001 on t001.bukrs = vbak.bukrs_vf
),
final_joined_with_flags as (
    select
  co_key,
  g_allocated_qty_primary_uom,
  g_availability_dt_yyyymmdd,
  g_bill_to_customer_nbr,
  g_cancel_dt_yyyymmdd,
  g_cancel_qty_primary_uom,
  g_company_currency_cd,
  g_customer_item_nbr,
  g_customer_po_line_nbr,
  g_customer_po_nbr,
  g_customer_po_type,
  g_customer_request_dt_yyyymmdd,
  g_delivery_schedule_line_nbr,
  g_flag_consignment_order,
  g_flag_has_parent,
  g_flag_inventory_fully_allocated,
  g_flag_is_parent,
  g_flag_is_transfer_order,
  g_flag_material_transacted,
  g_flag_on_hold,
  g_flag_open_to_ship,
  g_flag_return,
  g_flag_revenue_recognition,
  g_inco_terms,
  g_invoice_dt_yyyymmdd,
  g_item_nbr,
  g_last_actual_ship_dt_yyyymmdd,
  g_line_status_cd,
  g_open_qty_primary_uom,
  g_order_category,
  g_order_company_cd,
  g_order_currency_cd,
  g_order_dt_yyyymmdd,
  g_order_line_nbr,
  g_order_nbr,
  g_order_qty_order_uom,
  g_order_qty_primary_uom,
  g_order_type,
  g_order_uom_cd,
  g_original_customer_request_dt_yyyymmdd,
  g_original_promised_ship_dt_yyyymmdd,
  g_parent_order_line_nbr,
  g_payment_terms,
  g_plant_cd,
  g_primary_uom_cd,
  g_promised_ship_dt_yyyymmdd,
  g_scheduled_ship_dt_yyyymmdd,
  g_ship_to_customer_nbr,
  g_ship_to_delivery_days,
  g_shipment_mode,
  g_shipped_qty_primary_uom,
  g_source_system_cd,
  g_unit_cost_company_currency_primary_uom,
  g_unit_price_company_currency_primary_uom,
  g_unit_price_order_currency_primary_uom,
  plant_key,
  prod_key,
  prod_plant_key,
  sls_ord_key,
  sls_ord_sched_key,
  flag_is_blanket
from final_joined
),
sto_join as (
    select
    co_key,
    g_allocated_qty_primary_uom,
    g_availability_dt_yyyymmdd,
    g_bill_to_customer_nbr,
    g_cancel_dt_yyyymmdd,
    g_cancel_qty_primary_uom,
    g_company_currency_cd,
    g_customer_item_nbr,
    g_customer_po_line_nbr,
    g_customer_po_nbr,
    g_customer_po_type,
    g_customer_request_dt_yyyymmdd,
    g_delivery_schedule_line_nbr,
    g_flag_consignment_order,
    g_flag_has_parent,
    g_flag_inventory_fully_allocated,
    g_flag_is_parent,
    g_flag_is_transfer_order,
    g_flag_material_transacted,
    g_flag_on_hold,
    g_flag_open_to_ship,
    g_flag_return,
    g_flag_revenue_recognition,
    g_inco_terms,
    g_invoice_dt_yyyymmdd,
    g_item_nbr,
    g_last_actual_ship_dt_yyyymmdd,
    g_line_status_cd,
    g_open_qty_primary_uom,
    g_order_category,
    g_order_company_cd,
    g_order_currency_cd,
    g_order_dt_yyyymmdd,
    g_order_line_nbr,
    g_order_nbr,
    g_order_qty_order_uom,
    g_order_qty_primary_uom,
    g_order_type,
    g_order_uom_cd,
    g_original_customer_request_dt_yyyymmdd,
    g_original_promised_ship_dt_yyyymmdd,
    g_parent_order_line_nbr,
    g_payment_terms,
    g_plant_cd,
    g_primary_uom_cd,
    g_promised_ship_dt_yyyymmdd,
    g_scheduled_ship_dt_yyyymmdd,
    g_ship_to_customer_nbr,
    g_ship_to_delivery_days,
    g_shipment_mode,
    g_shipped_qty_primary_uom,
    g_source_system_cd,
    g_unit_cost_company_currency_primary_uom,
    g_unit_price_company_currency_primary_uom,
    g_unit_price_order_currency_primary_uom,
    plant_key,
    prod_key,
    prod_plant_key,
    sls_ord_key,
    sls_ord_sched_key,
    flag_is_blanket
from final_joined_with_flags
where g_flag_is_transfer_order = 'yes'
)
with final_select as (
    select
        concat_ws('|', 'gbl', g_order_company_cd) as co_key,
        g_allocated_qty_primary_uom,
        g_availability_dt_yyyymmdd,
        g_bill_to_customer_nbr,
        g_cancel_dt_yyyymmdd,
        g_cancel_qty_primary_uom,
        g_company_currency_cd,
        g_customer_item_nbr,
        g_customer_po_line_nbr,
        g_customer_po_nbr,
        g_customer_po_type,
        g_customer_request_dt_yyyymmdd,
        g_delivery_schedule_line_nbr,
        g_flag_consignment_order,
        g_flag_has_parent,
        g_flag_inventory_fully_allocated,
        g_flag_is_parent,
        g_flag_is_transfer_order,
        g_flag_material_transacted,
        g_flag_on_hold,
        g_flag_open_to_ship,
        g_flag_return,
        g_flag_revenue_recognition,
        g_inco_terms,
        g_invoice_dt_yyyymmdd,
        g_item_nbr,
        g_last_actual_ship_dt_yyyymmdd,
        g_line_status_cd,
        g_open_qty_primary_uom,
        g_order_category,
        g_order_company_cd,
        g_order_currency_cd,
        g_order_dt_yyyymmdd,
        g_order_line_nbr,
        g_order_nbr,
        g_order_qty_order_uom,
        g_order_qty_primary_uom,
        g_order_type,
        g_order_uom_cd,
        g_original_customer_request_dt_yyyymmdd,
        g_original_promised_ship_dt_yyyymmdd,
        g_parent_order_line_nbr,
        g_payment_terms,
        g_plant_cd,
        g_primary_uom_cd,
        g_promised_ship_dt_yyyymmdd,
        g_scheduled_ship_dt_yyyymmdd,
        g_ship_to_customer_nbr,
        g_ship_to_delivery_days,
        g_shipment_mode,
        g_shipped_qty_primary_uom,
        'gbl' as g_source_system_cd,
        g_unit_cost_company_currency_primary_uom,
        g_unit_price_company_currency_primary_uom,
        g_unit_price_order_currency_primary_uom,
        concat_ws('|', 'gbl', g_plant_cd) as plant_key,
        concat_ws('|', 'gbl', g_item_nbr) as prod_key,
        concat_ws('|', 'gbl', g_item_nbr, g_plant_cd) as prod_plant_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr) as sls_ord_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr, g_order_line_nbr, g_delivery_schedule_line_nbr) as sls_ord_sched_key,
        flag_is_blanket
    from final_joined_with_flags
    union all
    select
        concat_ws('|', 'gbl', g_order_company_cd) as co_key,
        g_allocated_qty_primary_uom,
        g_availability_dt_yyyymmdd,
        g_bill_to_customer_nbr,
        g_cancel_dt_yyyymmdd,
        g_cancel_qty_primary_uom,
        g_company_currency_cd,
        g_customer_item_nbr,
        g_customer_po_line_nbr,
        g_customer_po_nbr,
        g_customer_po_type,
        g_customer_request_dt_yyyymmdd,
        g_delivery_schedule_line_nbr,
        g_flag_consignment_order,
        g_flag_has_parent,
        g_flag_inventory_fully_allocated,
        g_flag_is_parent,
        g_flag_is_transfer_order,
        g_flag_material_transacted,
        g_flag_on_hold,
        g_flag_open_to_ship,
        g_flag_return,
        g_flag_revenue_recognition,
        g_inco_terms,
        g_invoice_dt_yyyymmdd,
        g_item_nbr,
        g_last_actual_ship_dt_yyyymmdd,
        g_line_status_cd,
        g_open_qty_primary_uom,
        g_order_category,
        g_order_company_cd,
        g_order_currency_cd,
        g_order_dt_yyyymmdd,
        g_order_line_nbr,
        g_order_nbr,
        g_order_qty_order_uom,
        g_order_qty_primary_uom,
        g_order_type,
        g_order_uom_cd,
        g_original_customer_request_dt_yyyymmdd,
        g_original_promised_ship_dt_yyyymmdd,
        g_parent_order_line_nbr,
        g_payment_terms,
        g_plant_cd,
        g_primary_uom_cd,
        g_promised_ship_dt_yyyymmdd,
        g_scheduled_ship_dt_yyyymmdd,
        g_ship_to_customer_nbr,
        g_ship_to_delivery_days,
        g_shipment_mode,
        g_shipped_qty_primary_uom,
        'gbl' as g_source_system_cd,
        g_unit_cost_company_currency_primary_uom,
        g_unit_price_company_currency_primary_uom,
        g_unit_price_order_currency_primary_uom,
        concat_ws('|', 'gbl', g_plant_cd) as plant_key,
        concat_ws('|', 'gbl', g_item_nbr) as prod_key,
        concat_ws('|', 'gbl', g_item_nbr, g_plant_cd) as prod_plant_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr) as sls_ord_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr, g_order_line_nbr, g_delivery_schedule_line_nbr) as sls_ord_sched_key,
        flag_is_blanket
    from sto_join
)
select * from final_select;