/**********************************************************************
artefact name :- f_sls_ord_sched
description   :- f_sls_ord_sched sql generated via multi-pass CTE pipeline
----------------------------------------------------------------------
change log
version :   date :        description :                       changed by
----------------------------------------------------------------------
0.0         2026-06-22    auto-generated multi-pass            ai_agent
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
    case 
        when vbap.meins = vbep.vrkme 
        then vbep.bmeng 
        else (marm.umrez / marm.umren) * vbep.bmeng 
    end as g_order_qty_primary_uom,
    case 
        when vbap.meins = vbep.vrkme 
        then vbep.bmeng 
        else vbep.wmeng 
    end as g_order_qty_order_uom,
    case 
        when vbap.meins = vbep.vrkme 
        then 'yes' 
        else 'no' 
    end as uom_check
from 
    vbep
left join vbap 
    on vbep.vbeln = vbap.vbeln 
    and vbep.posnr = vbap.posnr
left join marm 
    on vbap.matnr = marm.matnr 
    and vbep.vrkme = marm.meinh
),
vbfa_dedup as (
    select 
    concat_ws('|', 'gbl', vbfa.vbeln, vbfa.posnr, vbfa.fkimg) as co_key,
    vbfa.vbeln as g_order_nbr,
    vbfa.posnr as g_order_line_nbr,
    vbfa.fkimg as g_allocated_qty_primary_uom,
    null as g_availability_dt_yyyymmdd,
    case 
        when vbfa.parvw = 'RE/BP' then vbfa.kunnr
        else null
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null or vbap.abgru = '' then null
        when vbap.aedat = 0 then vbap.erdat
        else vbap.aedat
    end as g_cancel_dt_yyyymmdd,
    null as g_cancel_qty_primary_uom,
    case 
        when t001.waers = 'RMB' then 'CNY'
        else t001.waers
    end as g_company_currency_cd,
    vbap.kdmat as g_customer_item_nbr,
    null as g_customer_po_line_nbr,
    case 
        when vbkd.bstkd is not null then vbkd.bstkd
        else null
    end as g_customer_po_nbr,
    case 
        when vbkd.bsark is not null then vbkd.bsark
        else null
    end as g_customer_po_type,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') then trim(vbep.request_dt)
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
        when mska.sobkz = 'E' and (mska.kalab > 0 or mska.kains > 0 or mska.kaspe > 0 or mska.kavla > 0 or mska.kavin > 0 or mska.kavsp > 0) then 'yes'
        else 'no'
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = vbap.uepos then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case 
        when kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        when knvv.kdgrp in ('05', '06', '07') then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when tvep.bedsd = 'X' then 'yes'
        when tvep.bedsd is null and tvep.knttp in ('M', 'X') then 'yes'
        when vbep.order_qty_primary_uom = 0 then 'no'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp is not null and vbep.lifsp <> '' then 'yes'
        when vbak.lifsk is not null and vbak.lifsk <> '' then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold
from vbfa
left join vbap on vbfa.vbeln = vbap.vbeln and vbfa.posnr = vbap.posnr
left join vbep on vbfa.vbeln = vbep.vbeln and vbfa.posnr = vbep.posnr
left join marm on vbap.matnr = marm.matnr and vbep.vrkme = marm.meinh
left join mbew on vbap.matnr = mbew.matnr and vbap.werks = mbew.bwkey and mbew.mandt = '100' and trim(mbew.bwtar) = ''
left join vbak on vbep.vbeln = vbak.vbeln
left join t001 on t001.bukrs = vbak.bukrs_vf
left join mska on vbfa.vbeln = mska.vbeln and vbfa.posnr = mska.posnr
left join kna1 on vbak.kunnr = kna1.kunnr
left join knvv on vbak.kunnr = knvv.kunnr and vbak.vkorg = knvv.vkorg and vbak.vtweg = knvv.vtweg and vbak.spart = knvv.spart
left join tvep on vbep.ettyp = tvep.ettyp
),
order_schedule as (
    select 
    vbep.etenr as g_delivery_schedule_line_nbr,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    sum(vbep_bmeng.confirmed_qty) over (
        partition by vbep.vbeln, vbep.posnr 
        order by vbep.mbdat
        rows between unbounded preceding and current row
    ) as g_running_total_qty
from 
    vbep_bmeng
left join 
    vbep 
    on vbep_bmeng.vbeln = vbep.vbeln 
    and vbep_bmeng.posnr = vbep.posnr 
    and vbep_bmeng.etenr = vbep.etenr
),
order_shipment as (
    select
    vbfa_dedup.vbelv as g_order_nbr,
    vbfa_dedup.posnv as g_order_line_nbr,
    vbfa_dedup.vbeln as g_delivery_nbr,
    vbfa_dedup.posnn as g_delivery_line_nbr,
    vbfa_dedup.erdat as g_shipped_dt_yyyymmdd,
    sum(vbfa_dedup.qty) over (
        partition by vbfa_dedup.vbelv, vbfa_dedup.posnv
        order by vbfa_dedup.erdat, vbfa_dedup.vbeln
        rows between unbounded preceding and current row
    ) as g_shipped_qty_primary_uom,
    first_value(vbfa_dedup.erdat) over (
        partition by vbfa_dedup.vbelv, vbfa_dedup.posnv
        order by vbfa_dedup.erdat desc
    ) as g_last_actual_ship_dt_yyyymmdd
from
    vbfa_dedup
where
    vbfa_dedup.vbtyp_n = 'J' and
    vbfa_dedup.rn = 1
),
last_shipped_dt as (
    select 
    first_value(shipment_date) over (
        partition by schedule_id 
        order by shipment_date desc
    ) as g_last_actual_ship_dt_yyyymmdd
from 
    order_shipment
),
order_invoice as (
    select 
    vbfa.vbeln,
    vbfa.posnr,
    first_value(vbfa.erdat) over (
        partition by vbfa.vbeln, vbfa.posnr 
        order by vbfa.erdat desc
    ) as g_invoice_dt_yyyymmdd
from 
    vbfa
where 
    vbfa.vbtyp_n = 'M' 
    and vbfa.vbtyp_v = 'C'
),
tcurf_dedup as (
    select 
    t001.bukrs as g_order_company_cd,
    case 
        when trim(t001.waers) = 'RMB' then 'CNY' 
        else trim(t001.waers) 
    end as g_company_currency_cd,
    case 
        when trim(vbak.waerk) = 'RMB' then 'CNY' 
        else trim(vbak.waerk) 
    end as g_order_currency_cd,
    row_number() over (
        partition by tcurf.ffact, tcurf.tfact 
        order by tcurf.valid_from_dt desc
    ) as row_num
from 
    tcurf
left join t001 
    on tcurf.ffact = t001.waers
left join vbak 
    on tcurf.tfact = vbak.waerk
where 
    row_num = 1
),
final_joined as (
    select
    concat_ws('|', 'gbl', g_order_company_cd) as co_key,
    case 
        when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
        then (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp)
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    cast(null as string) as g_availability_dt_yyyymmdd,
    case 
        when bp.bill_to_customer_nbr is not null then bp.bill_to_customer_nbr
        else bp_alt.bill_to_customer_nbr
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
        when po.customer_po_nbr is not null then po.customer_po_nbr
        else po_alt.customer_po_nbr
    end as g_customer_po_nbr,
    case 
        when po.customer_po_type is not null then po.customer_po_type
        else po_alt.customer_po_type
    end as g_customer_po_type,
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
        when knvv.kdgrp in ('05', '06', '07') or kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when tvap.bedsd = 'X' or tvap.knttp in ('M', 'X') then 'yes'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp <> '' or vbak.lifsk <> '' or vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold,
    case 
        when vbak.autlf = 'X' or cancel_qty_primary_uom = order_qty_primary_uom or open_qty_primary_uom <= 0 then 'no'
        else 'yes'
    end as g_flag_open_to_ship,
    case 
        when vbak.vbtyp in ('H', 'T') then 'yes'
        else 'no'
    end as g_flag_return,
    case 
        when order_qty_primary_uom = 0 or vbak.vbtyp in ('A', 'B', 'D') or tvap.prsfd = 'X' then 'no'
        else 'yes'
    end as g_flag_revenue_recognition,
    vbap.inco1 as g_inco_terms,
    vbfa.erdat as g_invoice_dt_yyyymmdd,
    vbap.matnr as g_item_nbr,
    cast(null as string) as g_last_actual_ship_dt_yyyymmdd,
    case 
        when vbup.gbsta = 'A' then 'NOT YET PROCESSED'
        when vbup.gbsta = 'B' then 'PARTIALLY PROCESSED'
        when vbup.gbsta = 'C' then 'COMPLETELY PROCESSED'
        else 'NOT RELEVANT'
    end as g_line_status_cd,
    coalesce(order_qty_primary_uom - coalesce(shipped_qty, 0) - coalesce(cancel_qty_primary_uom, 0), 0) as g_open_qty_primary_uom,
    vbap.pstyv as g_order_category,
    t001k.bukrs as g_order_company_cd,
    case 
        when trim(vbak.waerk) = 'RMB' then 'CNY'
        else trim(vbak.waerk)
    end as g_order_currency_cd,
    vbak.audat as g_order_dt_yyyymmdd,
    vbep.posnr as g_order_line_nbr,
    vbep.vbeln as g_order_nbr,
    vbep.bmeng as g_order_qty_order_uom,
    vbep.bmeng as g_order_qty_primary_uom,
    vbak.auart as g_order_type,
    vbap.vrkme as g_order_uom_cd,
    vbep.edatu as g_original_customer_request_dt_yyyymmdd,
    vbep.edatu as g_original_promised_ship_dt_yyyymmdd,
    vbap.uepos as g_parent_order_line_nbr,
    vbak.zterm as g_payment_terms,
    vbap.werks as g_plant_cd,
    vbap.meins as g_primary_uom_cd,
    vbep.edatu as g_promised_ship_dt_yyyymmdd,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    case 
        when bp.ship_to_customer_nbr is not null then bp.ship_to_customer_nbr
        else bp_alt.ship_to_customer_nbr
    end as g_ship_to_customer_nbr,
    datediff(vbep.mbdat, vbep.edatu) as g_ship_to_delivery_days,
    vbak.vsbed as g_shipment_mode,
    coalesce(shipped_qty, 0) as g_shipped_qty_primary_uom,
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
from
    vbep_bmeng vbep
left join
    uom_conversion uom on vbep.vbeln = uom.vbeln and vbep.posnr = uom.posnr
left join
    order_schedule os on vbep.vbeln = os.vbeln and vbep.posnr = os.posnr
left join
    last_shipped_dt lst on vbep.vbeln = lst.vbeln and vbep.posnr = lst.posnr
left join
    order_invoice inv on vbep.vbeln = inv.vbeln and vbep.posnr = inv.posnr
left join
    tcurf_dedup tcurf on vbep.vbeln = tcurf.vbeln and vbep.posnr = tcurf.posnr
left join
    vbap on vbep.vbeln = vbap.vbeln and vbep.posnr = vbap.posnr
left join
    vbak on vbep.vbeln = vbak.vbeln
left join
    t001 on t001.bukrs = vbak.bukrs_vf
left join
    d_date d_dt on vbap.erdat = cast(d_dt.dt_key as string)
left join
    d_curncy_mth_rt on trim(d_curncy_mth_rt.yr_mth_nbr) = trim(d_dt.fscl_yr_prd_nbr) and trim(to_curncy_cd) = trim(vbak.waerk) and trim(from_curncy_cd) = case when trim(upper(t001.waers)) = 'RMB' then 'CNY' else trim(upper(t001.waers)) end
),
final_joined_with_flags as (
    select
    concat_ws('|', 'gbl', g_order_company_cd) as co_key,
    case 
        when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
        then mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    cast(null as string) as g_availability_dt_yyyymmdd,
    case 
        when bp.bill_to_customer_nbr is not null then bp.bill_to_customer_nbr
        else bp_alt.bill_to_customer_nbr
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null or trim(vbap.abgru) = '' then null
        when vbap.aedat = 0 then vbap.erdat
        else vbap.aedat
    end as g_cancel_dt_yyyymmdd,
    cast(null as string) as g_cancel_qty_primary_uom, -- TODO: review mapping
    case 
        when t001.waers = 'RMB' then 'CNY'
        else t001.waers
    end as g_company_currency_cd,
    vbap.matnr as g_customer_item_nbr,
    cast(null as string) as g_customer_po_line_nbr,
    case 
        when po.customer_po_nbr is not null then po.customer_po_nbr
        else po_alt.customer_po_nbr
    end as g_customer_po_nbr,
    case 
        when po.customer_po_type is not null then po.customer_po_type
        else po_alt.customer_po_type
    end as g_customer_po_type,
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
        when vbap.uepos is not null and vbap.uepos != 0 then 'yes'
        else 'no'
    end as g_flag_has_parent,
    case 
        when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
        then 'yes'
        else 'no'
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = any(select uepos from vbap where vbap.vbeln = vbap.vbeln) then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case 
        when knvv.kdgrp in ('05', '06', '07') or kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when tvap.bedsd = 'X' or tvap.knttp in ('M', 'X') then 'yes'
        when coalesce(order_qty_primary_uom, 0) = 0 then 'no'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp is not null then 'yes'
        when vbak.lifsk is not null then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold,
    case 
        when vbak.autlf = 'X' then 'no'
        when cancel_qty_primary_uom = order_qty_primary_uom then 'no'
        when open_qty_primary_uom <= 0 then 'no'
        else 'yes'
    end as g_flag_open_to_ship,
    case 
        when vbak.vbtyp in ('H', 'T') then 'yes'
        else 'no'
    end as g_flag_return,
    case 
        when order_qty_primary_uom = 0 then 'no'
        when vbak.vbtyp in ('A', 'B', 'D') then 'no'
        when tvap.prsfd = 'X' then 'yes'
        else 'no'
    end as g_flag_revenue_recognition,
    vbap.inco1 as g_inco_terms,
    vbfa.erdat as g_invoice_dt_yyyymmdd,
    vbap.matnr as g_item_nbr,
    cast(null as string) as g_last_actual_ship_dt_yyyymmdd,
    case 
        when vbup.gbsta = 'A' then 'NOT YET PROCESSED'
        when vbup.gbsta = 'B' then 'PARTIALLY PROCESSED'
        when vbup.gbsta = 'C' then 'COMPLETELY PROCESSED'
        else 'NOT RELEVANT'
    end as g_line_status_cd,
    case 
        when order_type = 'DEMO' and ship_lines.sttrg = '7' then 0
        when tvap.fkrel in ('A', 'H', 'J', 'K', 'M', 'O', 'P', 'Q', 'R', 'T', 'U', 'V', 'W') 
        then round(coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0), 4)
        when tvap.fkrel = '' then 0
        else round(coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0) - coalesce(cancel_qty_primary_uom, 0), 4)
    end as g_open_qty_primary_uom,
    vbap.pstyv as g_order_category,
    t001k.bukrs as g_order_company_cd,
    case 
        when vbak.waerk = 'RMB' then 'CNY'
        else vbak.waerk
    end as g_order_currency_cd,
    vbak.aedat as g_order_dt_yyyymmdd,
    vbep.posnr as g_order_line_nbr,
    vbep.vbeln as g_order_nbr,
    vbep.bmeng as g_order_qty_order_uom,
    vbep.bmeng as g_order_qty_primary_uom,
    vbak.auart as g_order_type,
    vbap.vrkme as g_order_uom_cd,
    vbep.edatu as g_original_customer_request_dt_yyyymmdd,
    vbep.edatu as g_original_promised_ship_dt_yyyymmdd,
    vbap.uepos as g_parent_order_line_nbr,
    vbak.zterm as g_payment_terms,
    vbap.werks as g_plant_cd,
    vbap.meins as g_primary_uom_cd,
    vbep.edatu as g_promised_ship_dt_yyyymmdd,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    case 
        when ship_to.ship_to_customer_nbr is not null then ship_to.ship_to_customer_nbr
        else ship_to_alt.ship_to_customer_nbr
    end as g_ship_to_customer_nbr,
    datediff(vbep.mbdat, vbep.edatu) as g_ship_to_delivery_days,
    vbak.vsbed as g_shipment_mode,
    vbfa.rfmng as g_shipped_qty_primary_uom,
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
from sto_join;