from django.db.models.signals import m2m_changed
from django.dispatch import receiver


@receiver(m2m_changed)
def enforce_bus_capacity(sender, instance, action, reverse, model, pk_set, **kwargs):
    """Prevent adding more children to a Trip than the bus capacity.

    This handler trims `pk_set` in the `pre_add` phase so the extra children
    are not added when they would exceed the bus capacity.
    """
    if action != 'pre_add':
        return

    # only handle Trip.children relation (model is Child)
    try:
        bus = instance.bus
    except Exception:
        return

    if not bus or getattr(bus, 'capacity', None) is None:
        return

    current = instance.children.count()
    incoming = len(pk_set)
    allowed = bus.capacity - current
    if allowed <= 0:
        # prevent all additions
        pk_set.clear()
        return

    if incoming > allowed:
        # trim the set to only allow up to `allowed` pks
        # convert to list to pick deterministic items
        allowed_pks = set(list(pk_set)[:allowed])
        pk_set.intersection_update(allowed_pks)
